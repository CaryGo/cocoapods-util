# cocoapods-util

cocoapods-util是一个pod插件集合，支持package、生成xcframework、linksource、repo push等功能。

## Installation

$ gem install cocoapods-util

## Usage

$ pod util --help

## 功能

### package

$ pod util package --help

通过podspec文件生成library、framework、xcframework。

- [x] 支持swift
- [x] 支持自定义配置dependency
- [x] 支持排除模拟器
- [x] 支持多平台（ios、osx、watchos、tvos）
- [x] 支持自定义设置工程的build settings（如：排除ios模拟器64位架构、设置支持的架构等）
    

###  xcframework

$ pod util xcframework --help

可以把现有的framework生成xcframework。

- 内部可以判断是某个平台的framework（如ios、osx、watchos），直接在framework同级目录生成xcframework。

### linksource

$ pod util linksource --help

源码二进制链接功能

### repo push

$ pod util repo push --help

推送私有pods仓库的命令

- 可以通过添加--skip-validate的选项跳过验证步骤。

### install list

$ pod util install list --help

列出安装的pod库