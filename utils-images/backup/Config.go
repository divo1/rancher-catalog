package main

import(
	"io/ioutil"
	"errors"
	"encoding/json"
)

type Mount struct {
	Src  string
	Dest string
}

type ContainerConfig struct {
	Name string
	Mounts []Mount
}

type Config struct {
	Configs []ContainerConfig
}

func NewConfig(filePath string) (Config, error) {
	file, err := ioutil.ReadFile(filePath)
	if err != nil {
		return Config{}, errors.New("Nie znaleziono config'a")
	}
	var config Config
	json.Unmarshal(file, &config)

	return config, nil
}

func (c Config) getContainersName() []string {
	var names []string
	
	for _, config := range c.Configs {
		names = append(names, config.Name)
	}
	
	return names
}