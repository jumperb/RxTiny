# RxTiny 微型oc响应式框架，以下是使用方法
```
@weakify(self);
[self addMenu:@"观察订阅" callback:^(id sender, id data) {
    @strongify(self);
    self.str = @"1";
    rxo(self, str).next(^(id v) {
        NSLog(@"%@", v);
    });
    self.str = @"2";
    self.str = nil;
}];

[self addMenu:@"自定义信号" callback:^(id sender, id data) {
    RxtSignal *s = [RxtSignal new];
    s.push(@"1");
    s.log(@"%@");
    s.push(@"2");
}];
[self addMenu:@"过滤" callback:^(id sender, id data) {
    RxtSignal *s = [RxtSignal new];
    s.filter(^BOOL(id v) {
        return [v isEqual:@"2"];
    }).log(@"%@");
    
    s.push(@"1");
    s.push(@"2");
    
}];
[self addMenu:@"映射" callback:^(id sender, id data) {
    RxtSignal *s = [RxtSignal new];
    s.map(^id(NSString *v) {
        if ([v isEqual:@"a"]) return @(1);
        if ([v isEqual:@"b"]) return @(2);
        return nil;
    }).toInt(^(int v) {
        NSLog(@"%d", v);
    });
    s.push(@"a");
    s.push(@"b");
}];
[self addMenu:@"合并" callback:^(id sender, id data) {
    @strongify(self);
    RxtSignal *s = [RxtSignal new];
    s.push(@"a");
    self.str = @"1";
    rxmerge(rxo(self, str), s).log(@"%@");
    self.str = @"2";
    s.push(@"b");
    
}];
[self addMenu:@"弄死" callback:^(id sender, id data) {
    @strongify(self);
    self.str = @"1";
    RxtSignal *s = rxo(self, str);
    s.log(@"%@");
    self.str = @"2";
    s.die();
    self.str = @"3";
}];

[self addMenu:@"弄死信号" callback:^(id sender, id data) {
    @strongify(self);
    self.str = @"1";
    RxtSignal *s2 = [RxtSignal new];
    RxtSignal *s = rxo(self, str);
    s.dieAt(s2).log(@"%@");
    self.str = @"2";
    s2.push(@"any");
    self.str = @"3";
}];

[self addMenu:@"一起死" callback:^(id sender, id data) {
    @strongify(self);
    self.str = @"1";
    RxtSignal *s = rxo(self, str);
    s.log(@"%@");
    self.str = @"2";
    if (YES) {
        NSObject *a = [NSObject new];
        s.dieWith(a);
    }            
    self.str = @"3";
}];

[self addMenu:@"信号绑定" callback:^(id sender, id data) {
    @strongify(self);
    self.str = @"1";
    RxtSignal *s2 = [RxtSignal new];
    s2.log(@"%@");
    rxo(self, str).bind(s2);
    self.str = @"2";
}];
[self addMenu:@"值绑定" callback:^(id sender, id data) {
    @strongify(self);
    rxsp(self, str2) = rxo(self, str);
    self.str = @"1";
    NSLog(@"%@" ,self.str2);
    self.str = @"2";
    NSLog(@"%@" ,self.str2);
}];

[self addMenu:@"不为空" callback:^(id sender, id data) {
    @strongify(self);
    rxo(self, str).log(@"可为空:%@");
    rxo(self, str).notNull().log(@"不为空:%@");
    self.str = @"1";
    self.str = nil;
    self.str = @"2";
}];

[self addMenu:@"取反" callback:^(id sender, id data) {
    @strongify(self);
    self.b1 = YES;
    rxo(self, b1).revertBool().toBool(^(BOOL v) {
        NSLog(v?@"YES":@"NO");
    });
}];

[self addMenu:@"其他转换" callback:^(id sender, id data) {
    @strongify(self);
    self.str = @"1234";
    rxo(self, str).toLongLong(^(long long v) {
        NSLog(@"%lli", v);
    });
    self.str = @"4566";
}];

[self addMenu:@"UI重用信号" callback:^(id sender, NSIndexPath *indexPath) {
    @strongify(self);
    self.color = [UIColor random];
    NSLog(@"见-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath");
}];
```

## 暂停 / 采样（本地新增）

### pausable: 闸门控制派发

gate 输出 BOOL：`YES` 放行 / `NO` 暂停。**暂停期间上游的值仍然会被记下来（末值），只是不派发**；`NO → YES` 时把末值补发一次。

```objc
RxtSignal *gate = [RxtSignal new];

rxo(player, currentTime)
    .pausable(gate)              // 闸门关着就只记末值，不刷新
    .asyncAtMain()
    .dieWith(self)
    .next(^(id v) {
        // 刷新 UI
    });

gate.push(@NO);   // 暂停：期间上游疯狂 push 也不会进 next，只留最后一个值
gate.push(@YES);  // 恢复：立刻补发暂停期间的末值（只补一次）
```

适用场景：页面/列表不可见、拖拽中、动画中——想冻住刷新，但回到前台要立刻是最新值，而不是等下一次数据变化。

### sample: 按采样信号吐末值

自身从不主动派发，只在 sampler 发信号时，把自己的末值吐一次。

```objc
rxo(player, currentTime)
    .sample(timerSignal)         // timerSignal 每 1s 一次
    .next(^(id v) { /* 1s 刷一次，永远是最新值 */ });
```

### 备注

- `RxtPause` 是两者的载体（`paused` + `emit`），一般不直接用。
- `paused` 是非原子的，闸门信号请在与上游同一个线程（一般是主线程）上 push。
- `pausable(nil)` / `sample(nil)` 不崩：前者退化为透传，后者永不派发。
