package config

import (
	"github.com/michael-golfi/rules/server/inference"
	"github.com/michael-golfi/rules/server/rule"
)

type Config struct {
	Name   string
	Schema []inference.Field
	Rules  rule.RuleRepository
}