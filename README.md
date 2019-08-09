# RxTiny 微型oc响应式框架，以下是使用方法
```
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
