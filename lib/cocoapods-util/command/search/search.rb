require_relative './image'

module Pod
    class Command
      class Util < Command
        class Search < Util
            self.summary = '为组件抽离提供帮助，快速搜索组件抽离的资源，如图片资源、html资源、mp3、mp4、json、xib、storyboard等资源。'
            self.description = <<-DESC
            为组件抽离提供帮助，快速搜索组件抽离的资源，如图片资源、html资源、mp3、mp4、json、xib、storyboard等资源。
            DESC
            self.command = 'search'
            self.abstract_command = true
      end
    end
  end
end