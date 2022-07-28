### **cocoapods-util是一个pod插件集合，集成了一些ios开发过程中提效的一些插件。**

# Installation

```
$ gem install cocoapods-util
```

# Usage

```
$ pod util --help
```

![fde10974894037fe52660a72e4057929.png](:/b79a26336903484ca5aa52a17cd0fe5d)

# 功能

## package

### 介绍

通过podspec文件生成library、framework、xcframework。

- [x] 支持swift
- [x] 支持自定义配置dependency
- [x] 支持排除模拟器
- [x] 支持多平台（ios、osx、watchos、tvos）
- [x] 支持自定义设置工程的build settings（如：排除ios模拟器64位架构、设置支持的架构等）

```
$ pod util package --help
```

![74dd1a40ffa3af3744fdf79384fdebdb.png](:/dae2740afb4d486886f03f1be761d490)

### 示例

#### 生成xcfrmework/framework/library

生成AFNetworking组件的xcframework 进入AFNetworking源码的根目录下，执行下面的命令

```
$ pod util package AFNetworking.podspec --force --local --xcframework

$ pod util package AFNetworking.podspec --force --local --framework

$ pod util package AFNetworking.podspec --force --local --library
```

![d5410dda08a99ee977dd6ca8af98ef74.png](:/f6f3aab96210432eb4fa2b63f6452728)

#### 排除模拟器

如果你不需要编译模拟器架构，可以添加--exclude-sim

```
$ pod util package AFNetworking.podspec --force --local --xcframework --exclude-sim
```

#### 平台设置

如果你只需要编译ios架构下的xcframework，可以添加--platforms=ios

```
$ pod util package AFNetworking.podspec --force --local --xcframework --exclude-sim --platforms=ios
```

#### build settings配置

如果你想要做一些build settings特殊配置，可以添加 --build-settings，如设置编译选项排除模拟器arm64架构。理论上来讲，可以像直接操作工程一样，灵活的配置build settings

- 如设置排除arm64位架构

```
$ --build-settings='{"EXCLUDED_ARCHS[sdk=iphonesimulator*]":"arm64"}'
```

- 设置编译swift生成swiftinterface文件

```
$ -build-settings='{"BUILD_LIBRARY_FOR_DISTRIBUTION":"YES"}'
```

- 或者你想设置多个编译选项

```
$ -build-settings='{"EXCLUDED_ARCHS[sdk=iphonesimulator*]":"arm64","BUILD_LIBRARY_FOR_DISTRIBUTION":"YES","VALID_ARCHS":"arm64"}'
```

#### 自定义dependencies

如果你依赖的组件并没有发布到私有仓库，你只是分支依赖！ 如果你依赖的组件和官方源有冲突，你改需要指定source源！ 这时候你可以通过配置`--dependency-config={}`选项指定仓库分支、tag或指定source源。

```
$ --dependency-config='{"PodA":{"git":"xxx","branch":"xxx"},"PodB":{"source":"xxx"}}'
```

## xcframework

### 介绍

可以把现有的framework生成xcframework。

- 内部可以判断是某个平台的framework（如ios、osx、watchos），直接在framework同级目录生成xcframework。

![132d6cec7bc64488deca731d37438cdd.png](:/1b1d92444fb246958c8b9b1570d399c7)

### 示例

生成Alamofire的framework

```
$ pod util xcframework Alamofire.framework --force 
```

![e32ea9af2dfae1e3d6b03f0278c33057.png](:/a1ce528418ae417fb89ca8774e80b55e)

![23332974a4941bae97010afb4b4d4c1c.png](:/b5cab59f497f4f1eb8333723fcb4e78f)

## linksource

源码二进制链接功能。

```
$ pod util linksource --help
```

![b605570c681e5d7877f08458cfd1dbc7.png](:/41b6ddce3bd54939b27e25eac718b0d8)

## repo push

推送私有pods仓库的命令。

- 可以通过添加--skip-validate的选项跳过验证步骤。

```
$ pod util repo push --help
```

![2947331da6ee0c269dbd6ea073d15d4e.png](:/acdfa5cd918d4d4eb0317888a92bf119)

该命令是一个提效命令，在推送自己私有仓库的时候可以通过设置--skip-validate选项跳过验证直接推送到私有仓库。

```
$ pod util repo push [yourSpecs] [xxx.podspec] --skip-validate
```

当然你也可以不使用--skip-validate，参数设置和`pod repo push`命令一致

## install list

列出安装的pod库及相关依赖信息。

- 该命令同样为提效命令，可以省去开发者自己去阅读Podfile.lock文件的时间，直接友好的提示开发者
- 可以清晰的看出引用的组件个数、组件依赖、组件分支tag信息、仓库地址等有效信息

```
$ pod util install list --help
```

![f839eae390ea7871a5afecec093dd39c.png](:/9a2bce2aa1db4794a8e72a51e0d97f73)

可以在Podfile.lock的同级目录下执行或指定Podfile.lock的路径

```
$ pod util install list --showmore
$ pod util install list ~/Desktop/xxxx/ProjectA/Podfile.lock --showmore
```

![3be13cd62a8450a7c8b2a3fa728984c6.png](:/72b1fb686c15458e951460b20b74f845)