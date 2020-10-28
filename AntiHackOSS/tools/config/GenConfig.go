/*
 * Copyright 2020 DeNA Co., Ltd.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package main

import (
  "fmt"
  "os"
  "log"
  "encoding/json"
  "flag"
  "io"
  "bytes"
)

var DEFAULT_SPLIT_LEVEL int = 1

type Flatten struct {
  Name string `json:"name"`
  Seed string `json:"seed"`
  SplitLevel int `json:"split_level"`
  SearchType string `json:"search_type"`
}

type Config struct {
  Build_seed string `json:"build_seed"`
  Overall_obfuscation int `json:"overall_obfuscation"`
  Enable_obfuscation int `json:"enable_obfuscation"`
  Flattens []Flatten `json:"flatten"`
}

func GetConfig(path string) Config {
  jsonPath := path
  jsonFile, err := os.Open(jsonPath)
  if err != nil {
    check(fmt.Sprintf("%v のファイルが開けませんでした。", path), err)
  }
  defer jsonFile.Close()

  var config Config
  decoder := json.NewDecoder(jsonFile)
  decoder.DisallowUnknownFields()
  if err := decoder.Decode(&config); err != nil && err != io.EOF {
    check(fmt.Sprintf("%v のJSONのパースに失敗しました。", path), err)
  }
  return config
}

func CalcHash(data []byte, start uint64, size uint64) uint64{
  const BLOCK_SIZE uint64 = 4
  const BASE uint64 = 617365819018153
  var hash uint64 = 0
  i := start
  var j uint64 = 0

  for ; i+BLOCK_SIZE < start+size; i += BLOCK_SIZE {
    hash *= BASE
    var tmp uint64 = 1
    for j = 0; j < BLOCK_SIZE; j++ {
      hash += uint64(data[i+j]) * tmp
      tmp <<= 8
    }
  }
  for ; i < start+size; i++ {
    hash = hash*BASE + uint64(data[i])
  }
  return hash
}



func (config *Config) UnmarshalJSON(data []byte) error {
  type xConfig Config
  defaultConfig := &xConfig{Overall_obfuscation: 0, Enable_obfuscation: 1}
  decoder := json.NewDecoder(bytes.NewReader(data))
  decoder.DisallowUnknownFields()
  if err := decoder.Decode(defaultConfig); err != nil && err != io.EOF {
    return err
  }
  *config = Config(*defaultConfig)
  return nil
}

func (flatten *Flatten) UnmarshalJSON(data []byte) error {
  type xFlatten Flatten
  xf := &xFlatten{Seed: "", SplitLevel: DEFAULT_SPLIT_LEVEL}
  decoder := json.NewDecoder(bytes.NewReader(data))
  decoder.DisallowUnknownFields()
  if err := decoder.Decode(xf); err != nil && err != io.EOF {
    return err
  }
  *flatten = Flatten(*xf)
  if flatten.Name == "" {
    log.Fatalf("flattenでnameが定義されていません。")
  }
  return nil
}

func check(message string, e error) {
  if e != nil {
    log.Print(message)
      log.Fatalf("Error: %v\n", e)
  }
}

func flattenContainsName(f []Flatten, name string) bool {
  for _, v := range f {
    if name == v.Name {
      return true
    }
  }
  return false
}

func contains(s []string, e string) bool {
  for _, v := range s {
    if e == v {
      return true
    }
  }
  return false
}

func main() {
  homeDir := os.Getenv("DECLANG_HOME")
  if len(homeDir) == 0 {
    homeDir = os.Getenv("HOME")
  }

  pathPtr := flag.String("path", homeDir+"/.DeClang/", "config file path")
  seedPtr := flag.String("seed", "", "a seed")
  flag.Parse()

  //if len(os.Args) != 1 && len(os.Args) != 2 && len(os.Args) != 3 {
  //  fmt.Println("usage: gen_config_{linux,mac,windows} [seed] [path_to_config.pre.json]")
  //  os.Exit(1)
  //}
  fmt.Printf("[GenConfig]: Generate config.json\n")

  var config Config
  var jsonOutPath string
  jsonOutPath = *pathPtr + "/config.json"
  config = GetConfig(*pathPtr+"/config.pre.json")

  if len(*seedPtr) > 0 {
    config.Build_seed = *seedPtr
  }
  buildSeed := config.Build_seed

  //generate seed for flattening
  for i := 0; i < len(config.Flattens); i++ {
    funcName := config.Flattens[i].Name
    seed := config.Flattens[i].Seed
    if seed == "" {
      str := []byte(buildSeed + funcName)
      hash := CalcHash(str, 0, uint64(len(str)) )
      seed = fmt.Sprintf("%016x%016x", hash, hash)
      config.Flattens[i].Seed = seed
    }
    fmt.Printf("[GenConfig]: Flatten %s using %s\n", funcName, seed)
  }

  configStr, err := json.MarshalIndent(config, "", "    ")
  check("JSON形式への変換に失敗しました。", err)

  jsonOutFile, err := os.Create(jsonOutPath)
  check(fmt.Sprintf("%v のファイルが開けませんでした。", jsonOutPath), err)
  defer jsonOutFile.Close()

  jsonOutFile.Write(configStr)
}
