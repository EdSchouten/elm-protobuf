package main

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strings"
	"unicode"
	"unicode/utf8"

	"github.com/golang/protobuf/proto"

	"github.com/golang/protobuf/protoc-gen-go/descriptor"
	"github.com/golang/protobuf/protoc-gen-go/generator"
	plugin "github.com/golang/protobuf/protoc-gen-go/plugin"
)

var (
	// Maps each type to the file in which it was defined.
	typeToFile = map[string]string{}
)

func main() {
	data, err := ioutil.ReadAll(os.Stdin)
	if err != nil {
		log.Fatalf("Could not read request from STDIN: %v", err)
	}

	req := &plugin.CodeGeneratorRequest{}

	err = proto.Unmarshal(data, req)
	if err != nil {
		log.Fatalf("Could not unmarshal request: %v", err)
	}

	// Remove useless source code data.
	for _, inFile := range req.GetProtoFile() {
		inFile.SourceCodeInfo = nil
	}

	log.Printf("Input data: %v", proto.MarshalTextString(req))

	resp := &plugin.CodeGeneratorResponse{}

	for _, inFile := range req.GetProtoFile() {
		log.Printf("Processing file %s", inFile.GetName())
		outFile, err := processFile(inFile)
		if err != nil {
			log.Fatalf("Could not process file: %v", err)
		}
		resp.File = append(resp.File, outFile)
	}

	data, err = proto.Marshal(resp)
	if err != nil {
		log.Fatalf("Could not marshal response: %v [%v]", err, resp)
	}

	_, err = os.Stdout.Write(data)
	if err != nil {
		log.Fatalf("Could not write response to STDOUT: %v", err)
	}
}

func processFile(inFile *descriptor.FileDescriptorProto) (*plugin.CodeGeneratorResponse_File, error) {
	if inFile.GetSyntax() != "proto3" {
		return nil, fmt.Errorf("Only proto3 syntax is supported")
	}

	outFile := &plugin.CodeGeneratorResponse_File{}

	inFilePath := inFile.GetName()
	inFileDir, inFileName := filepath.Split(inFilePath)

	shortModuleName := firstUpper(strings.TrimSuffix(inFileName, ".proto"))

	fullModuleName := ""
	outFileName := ""
	for _, segment := range strings.Split(inFileDir, "/") {
		if segment == "" {
			continue
		}
		fullModuleName += firstUpper(segment) + "."
		outFileName += firstUpper(segment) + "/"
	}
	fullModuleName += shortModuleName
	outFileName += shortModuleName + ".elm"

	outFile.Name = proto.String(outFileName)

	b := &bytes.Buffer{}
	fg := NewFileGenerator(b)

	fg.GenerateModule(fullModuleName)
	fg.GenerateImports()
	fg.GenerateRuntime()

	var err error

	// Top-level enums.
	for _, inEnum := range inFile.GetEnumType() {
		typeToFile[strings.TrimPrefix(inFile.GetPackage() + "." + inEnum.GetName(), ".")] = inFile.GetName()

		err = fg.GenerateEnumDefinition("", inEnum)
		if err != nil {
			return nil, err
		}

		err = fg.GenerateEnumDecoder("", inEnum)
		if err != nil {
			return nil, err
		}

		err = fg.GenerateEnumEncoder("", inEnum)
		if err != nil {
			return nil, err
		}
	}

	// Top-level messages.
	for _, inMessage := range inFile.GetMessageType() {
		typeToFile[strings.TrimPrefix(inFile.GetPackage() + "." +inMessage.GetName(), ".")] = inFile.GetName()

		err = fg.GenerateEverything(inFile.GetName(), "", inMessage)
		if err != nil {
			return nil, err
		}
	}

	outFile.Content = proto.String(b.String())

	return outFile, nil
}

func (fg *FileGenerator) GenerateModule(moduleName string) {
	fg.P("module %s exposing (..)", moduleName)
}

func (fg *FileGenerator) GenerateImports() {
	fg.P("")
	fg.P("import Json.Decode as JD")
	fg.P("import Json.Encode as JE")

	// This is importing literally everything.
	// TODO: Trim deps.
	fg.P("")
	for _, f := range typeToFile {
		fg.P("import %s", moduleName(f))
	}
}

func (fg *FileGenerator) GenerateEverything(fileName string, prefix string, inMessage *descriptor.DescriptorProto) error {
	newPrefix := prefix + inMessage.GetName() + "_"
	var err error

	err = fg.GenerateMessageDefinition(fileName, prefix, inMessage)
	if err != nil {
		return err
	}

	for _, inEnum := range inMessage.GetEnumType() {
		err = fg.GenerateEnumDefinition(newPrefix, inEnum)
		if err != nil {
			return err
		}
	}

	err = fg.GenerateMessageDecoder(fileName, prefix, inMessage)
	if err != nil {
		return err
	}

	for _, inEnum := range inMessage.GetEnumType() {
		err = fg.GenerateEnumDecoder(newPrefix, inEnum)
		if err != nil {
			return err
		}
	}

	err = fg.GenerateMessageEncoder(fileName, prefix, inMessage)
	if err != nil {
		return err
	}

	for _, inEnum := range inMessage.GetEnumType() {
		err = fg.GenerateEnumEncoder(newPrefix, inEnum)
		if err != nil {
			return err
		}
	}

	// Nested messages.
	for _, nested := range inMessage.GetNestedType() {
		fg.GenerateEverything(fileName, newPrefix, nested)
	}

	return nil
}

func elmTypeName(in string) string {
	return camelCase(in)
}

func elmFieldName(in string) string {
	return firstLower(camelCase(in))
}

func elmEnumValueName(in string) string {
	return camelCase(strings.ToLower(in))
}

func decoderName(fileName string, typeName string) string {
	packageName, messageName := convert(typeName)

	file := typeToFile[strings.TrimPrefix(typeName, ".")]
	// Do not qualify local symbols.
	if file != fileName {
		packageName = moduleName(file)
	}

	if packageName == "" {
		return firstLower(messageName) + "Decoder"
	} else {
		return packageName + "." + firstLower(messageName) + "Decoder"
	}
}

func defaultEnumValue(typeName string) string {
	packageName, messageName := convert(typeName)

	if packageName == "" {
		return firstLower(messageName) + "Default"
	} else {
		return packageName + "." + firstLower(messageName) + "Default"
	}
}

func encoderName(typeName string) string {
	packageName, messageName := convert(typeName)

	if packageName == "" {
		return firstLower(messageName) + "Encoder"
	} else {
		return packageName + "." + firstLower(messageName) + "Encoder"
	}
}

func elmFieldType(fileName string, field *descriptor.FieldDescriptorProto) string {
	inFieldName := field.GetTypeName()
	packageName, messageName := convert(inFieldName)

	file := typeToFile[strings.TrimPrefix(field.GetTypeName(), ".")]
	log.Printf("field type: %v", field.GetTypeName())
	log.Printf("file: %v", file)
	// Do not qualify local symbols.
	if file != fileName {
		packageName = moduleName(file)
	}

	if packageName == "" {
		return messageName
	} else {
		return packageName + "." + messageName
	}
}

func moduleName(fileName string) string {
	fullModuleName := ""
	for _, segment := range strings.Split(strings.TrimSuffix(fileName, ".proto"), "/") {
		if segment == "" {
			continue
		}
		fullModuleName += firstUpper(segment) + "."
	}
	return strings.TrimSuffix(fullModuleName, ".")
}

// Returns package name and message name.
func convert(inType string) (string, string) {
	segments := strings.Split(inType, ".")
	outPackageSegments := []string{}
	outMessageSegments := []string{}
	for _, s := range segments {
		if s == "" {
			continue
		}
		r, _ := utf8.DecodeRuneInString(s)
		if unicode.IsLower(r) {
			// Package name.
			outPackageSegments = append(outPackageSegments, firstUpper(s))
		} else {
			// Message name.
			outMessageSegments = append(outMessageSegments, firstUpper(s))
		}
	}
	return strings.Join(outPackageSegments, "."), strings.Join(outMessageSegments, "_")
}

func jsonFieldName(field *descriptor.FieldDescriptorProto) string {
	return field.GetJsonName()
}

func firstLower(in string) string {
	if in == "" {
		return ""
	}
	if len(in) == 1 {
		return strings.ToLower(in)
	}
	return strings.ToLower(string(in[0])) + string(in[1:])
}

func firstUpper(in string) string {
	if in == "" {
		return ""
	}
	if len(in) == 1 {
		return strings.ToUpper(in)
	}
	return strings.ToUpper(string(in[0])) + string(in[1:])
}

func camelCase(in string) string {
	// Remove any additional underscores, e.g. convert `foo_1` into `foo1`.
	return strings.Replace(generator.CamelCase(in), "_", "", -1)
}
