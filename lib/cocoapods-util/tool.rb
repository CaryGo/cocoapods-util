class Module
    def class_alias_method(to, from)
      # https://tieba.baidu.com/p/5535445605?red_tag=0735709674  贴吧大神给出的方案
      # 类方法可以看做singleton class（单例类）的实例方法，下面两个方法都可以，上面这个方式也适用于早期的ruby版本
      (class << self;self;end).send(:alias_method, to, from)
      # self.singleton_class.send(:alias_method, to, from)
    end

    def class_attr_accessor(symbol)
        self.class.send(:attr_accessor, symbol)
    end
end