#!/bin/env pwsh
param(
    [Parameter(Mandatory = $false)]
    [string]$BaseUrl
)
Import-Module $PSScriptRoot/BuildUtils.psm1 -Force

Sync-Icons

$baseUrlArg = $BaseUrl ? @("--baseurl", $BaseUrl) : @()
bundle exec jekyll build @baseUrlArg
