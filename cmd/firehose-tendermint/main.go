package main

import (
	"fmt"

	"github.com/figment-networks/firehose-tendermint/tools"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"github.com/streamingfast/derr"
	"github.com/streamingfast/dlauncher/flags"
	"github.com/streamingfast/dlauncher/launcher"
	"github.com/streamingfast/logging"
	"go.uber.org/zap"
)

var (
	userLog  = launcher.UserLog
	zlog     *zap.Logger
	allFlags = map[string]bool{}

	rootCmd = &cobra.Command{
		Use:     "firehose-tendermint",
		Short:   "Firehose services for Tendermint-based blockchains",
		Version: versionString(),
	}
)

func init() {
	logging.Register("main", &zlog)
}

func main() {
	cobra.OnInitialize(func() {
		allFlags = flags.AutoBind(rootCmd, "FH")
	})

	initCommonFlags(rootCmd.PersistentFlags())
	rootCmd.PersistentPreRunE = preRun

	rootCmd.AddCommand(
		initCommand,
		startCommand,
		resetCommand,
		tools.Cmd,
	)

	derr.Check("registering application flags", launcher.RegisterFlags(startCommand))
	derr.Check("executing root command", rootCmd.Execute())
}

func preRun(cmd *cobra.Command, args []string) error {
	if configFile := viper.GetString("config"); configFile != "" {
		if fileExists(configFile) {
			if err := launcher.LoadConfigFile(configFile); err != nil {
				return err
			}
		}
	}

	cfg := launcher.DfuseConfig[cmd.Name()]
	if cfg != nil {
		for k, v := range cfg.Flags {
			validFlag := false
			if _, ok := allFlags[k]; ok {
				viper.SetDefault(k, v)
				validFlag = true
			}
			if !validFlag {
				return fmt.Errorf("invalid flag %v", k)
			}
		}
	}

	launcher.SetupLogger(&launcher.LoggingOptions{
		WorkingDir:    viper.GetString("data-dir"),
		Verbosity:     viper.GetInt("verbose"),
		LogFormat:     viper.GetString("log-format"),
		LogToFile:     viper.GetBool("log-to-file"),
		LogListenAddr: viper.GetString("log-level-switcher-listen-addr"),
	})

	launcher.SetupTracing()

	return nil
}