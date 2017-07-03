package main

import(
	"os"
	"io/ioutil"
)

const (
	CONFIG_FILE_PATH = "./config.json"
)

func getConfigFilePath() string {
	return CONFIG_FILE_PATH
}

func main() {
	InitLog(ioutil.Discard, os.Stdout, os.Stdout, os.Stderr)

	Info.Print("Starting backup")
	config, err := NewConfig(getConfigFilePath())
	if (err != nil) {
		panic(err)
	}

	backup, err := NewBackup()
	if (err != nil) {
		panic(err)
	}
	docker, err := NewDocker()
	if (err != nil) {
		panic(err)
	}
	
	Info.Print("Config: ", config.Configs)
	
	for _, containerConfig := range config.Configs {
		if docker.isRuningContainerWithName(containerConfig.Name) == false {
			Error.Print("Getting container with specific name: ", containerConfig.Name)
			continue
		}
		Info.Print("Founded container: ", containerConfig)
		
		for _, mount := range containerConfig.Mounts {
			dockerConfig := backup.getDockerConfigToStore(containerConfig.Name, mount.Src, mount.Dest)
			Info.Print("Get docker config: ", dockerConfig)
			docker.startNewContainer(dockerConfig)
		}
	}

	Info.Print("Done")
}