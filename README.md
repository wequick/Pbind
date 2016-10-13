# Pbind

[![CI Status](http://img.shields.io/travis/wequick/Pbind.svg?style=flat)](https://travis-ci.org/wequick/Pbind)
[![Version](https://img.shields.io/cocoapods/v/Pbind.svg?style=flat)](http://cocoapods.org/pods/Pbind)
[![License](https://img.shields.io/cocoapods/l/Pbind.svg?style=flat)](http://cocoapods.org/pods/Pbind)
[![Platform](https://img.shields.io/cocoapods/p/Pbind.svg?style=flat)](http://cocoapods.org/pods/Pbind)

Pbind, a data binder with Plist.

[中文文档](https://github.com/wequick/Pbind/wiki)

## Snapshot (Playground)

![Pbind playground](https://cloud.githubusercontent.com/assets/5291591/18739105/bc203a7a-80d3-11e6-98f9-fdcacecf4197.gif)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

Pbind is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Pbind"
```

## Plist Reference

Key           | Value                | Description
:------------ | :------------------- | ------------
properties    | **Dictionary**         | keyed values for self
tagproperties | **Array\<Dictionary>**  | keyed values for tagged subviews (array index map to subview's tag, start at 1), recommended way to config subviews.
subproperties | **Array\<Dictionary>**  | keyed values for subviews (array index map to subview's index, start at 0)

Each property is composed of key and value. The **key** descripts owner's **key path**, the **value** for the **key** can be any constants of plist or an **Rainbow-Expression**.

#### Plist Key (Left column of Plist)

```
usage: [tag][key]
```
1. Tag
	
   Tag           | Parse to                 | Desctiption                | e.g.
   :------------ | :----------------------- | :------------------------- | ------------------
                 | @property                | for UIView's defined key   | hidden
    \+           | Addition key             | for UIView's undefined key | +mykey
    !            | Control event            | for UIControl only         | !change (UIControlEventValueChanged)<br/>!click (UIControlEventTouchUpInside)


#### Plist Value (Right column of Plist)

1. Constant (_**@see PBValueParser**_)
	
	Tag           | Parse to                 | e.g.
	:------------ | :----------------------- | ------------
	 #            | UIColor                  | #FF00FF
	 ##           | CGColor                  | ##FF00FF
	 @            | Subscript                | @[1,2,3]; @{title:1}
	 :            | Enum                     | :left = NSTextAlignmentLeft
	 {{           | Rect                     | {{0,0},{1080,44}
	 {            | Size\|Point\|EdgeInsets  | {1080,44} \| {0,2,0,2}
	 {F:          | Font               	     | {F:MicrosoftYaHei,bold,14}<br>{F:itailc,14}<br>{F:14}
	 
	 For matching the screen size, the pixel value of `Rect`, `Size` and `Font` will be automatically scale by your sketch width. The default sketch width is 1080, you can specify it by `[Pbind setSketchWidth:]`.
	 
	 After you do this, you can directly use the pixel value marked in the sketch by your UI designer.
	 
	1.1 Enum
	
	Name          | Map to                  
	:------------ | :-----------------------
	 :left        | NSTextAlignmentLeft
	 :right       | NSTextAlignmentRight
	 :center      | NSTextAlignmentCenter
	 :/           | UITableViewCellAccessoryCheckmark
	 :i           | UITableViewCellAccessoryDetailButton
	 :>           | UITableViewCellAccessoryDisclosureIndicator
	 :value1      | UITableViewCellStyleValue1
	 :value2      | UITableViewCellStyleValue2
	 :subtitle    | UITableViewCellStyleSubtitle
	
	1.1.1 User-defined Enum
	
	```
	/* e.g.
	 *  - plist: :your_enum1
	 *  - output: 1
	 *  - plist: :your_enum2
	 *  - output: 2
	 */
	[PBValueParser registerEnums:@{@"{your_enum1}": @1,
	                               @"{your_enum2{": @2}];
	```

2. Variable (_**@see PBExpression**_)
	
	```
	usage: [unary-operator][tag][accessory][variable][logic-operator][rvalue][:][rvalueOfNot]
	```
	
    2.1 Tag (_**@see PBVariableMapper**_)  
       
    Tag           | Map to               | e.g.
	:------------ | :------------------- | ------------
	 $            | root view data       | $records
	 .            | target view          | .frame.size
	 .$           | target view data     | .$name
	 @            | active controller    | @title
	 >            | PBForm input text    | >birth
	 >@           | PBForm input value   | >@birth
	
    2.1.1  User-defined Variable Tag
    
    User-defined tag accepts one-char only, as if you defined `D`, then you can use `$D.` in plist.
    
	```
	/* e.g.
	 *  - plist: $D.userInfo
	 *  - mapto: [[NSUserDefaults standardDefaults] valueForKey:@"userInfo"]
	 */
	[PBVariableMapper registerTag:'D' withMapper:^id(id data, id target) {
        return [NSUserDefaults standardDefaults];
    }];
	```

	2.2 Operator
	
	Operator      | Description              | e.g.
	:------------ | :----------------------- | ------------
	 !            | logic not                | !$success
	 \-           | negative or minus        | -$height; $count-1
	 <            | less than                | $count<2
	 \>           | greater than             | $count>7
	 = or ==      | equal to                 | $count=3; $count==3
	 !=           | not equal to             | $count!=2
	 <=           | less equal               | $count<=7
	 \>=          | greater equal            | $count>=3
	 \+           | plus                     | $count+2
	 \*           | times                    | $count*7
	 /            | devide                   | $count/3
	 ?:           | test                     | $value?:2; $flag?1:2
	 
	2.3 Accessory flags
	
	Accessory     | Description                   | e.g.
	:------------ | :---------------------------- | ------------
	 _            | one-way binding (data->view)  | $_selected
	 __           | duplex binding (data<->view)  | $__tabIndex
	 ~            | set value with animated       | ~$contentSize

3. Formatter (_**@see PBMutableExpression**_)

	```
	usage: %[tag:option]( format ),$arg1,$arg2,...
	```

	3.1 Tag

    Tag           | Description                       | e.g.
	:------------ | :-------------------------------- | ------------
	              | string format                     | %(goods:%@, money:%.2f),$title,$money
     !            | format only if args are not empty | %!(goods:%@, money:%.2f),$title,$money
	 JS           | javascript evaluator              | %JS('goods:' + $1 + ', money:' + $2),$title,$money
	 AT           | attributed string                 | %AT(Hello |%@),$man;#fff-{F:13}|{F:14}
	
	3.1.1 User-defined Format Tag (_**@see PBVariableEvaluator**_)
	
	```
	/* e.g. Format string to array
	 *  - plist: %S2A(/),$str
     *  - input: str="a/b/c"
     *  - output: @[@"a",@"b",@"c"]
     */
	[PBVariableEvaluator registerTag:@"S2A" withFormatterer:^id(NSString *format, id value) {
        return [value componentsSeparatedByString:format];
    }];
	```
	
	3.1.2 Javascript Evaluator (_**@see PBVariableEvaluator**_)
	
	Pbind use JavascriptCore to evaluate js.
	
	To use Javascript Evaluator, simply declare `%JS( scripts ),vars` in plist. Pbind will pass the variables as `$1`, `$2` ... `$N` to the scripts.
	
	Futher more, you can define the return value type by an option like `%JS:type`, the type here is default to `string` and can also be `bool`, `int32`, `date`, `rect` and etc. They are refer to `[JSValue toXx]`.

    3.1.3 String Formatter (_**@see PBString, PBStringFormatter**_)
	
	Flag    | Description                                             | e.g.
	:------ | :------------------------------------------------------ | --------
	 #      | Number format, accepts _**NSNumber**_ arg               | %(%#.2f),$number
	 J      | Json, accepts _**NSDictionary, NSArray**_ arg           | %(%J),$dict
	 \<t\>  | Date format, accepts _**NSDate, NSNumber**_ arg         | %(%\<t:yyyy-MM-dd\>),$date
	 \<T\>  | Date template, accepts _**NSDate, NSNumber**_ arg       | %(%\<T:MMMy\>),$date
	 \<UE\> | URL Encoded, accepts _**NSString**_ arg                 | %(%\<UE\>),$param
	 \<UEJ\>| Encoded Json, accepts _**NSDictionary, NSArray**_ arg   | %(%\<UEJ\>),$dict
		
    3.1.4 User-defined Format Flag (_**@see PBStringFormatter**_)
    
    ```
    /* e.g. Format array to string
     *  - plist: %(%<A2S:/>),$arr
     *  - input: arr=@[@"a",@"b",@"c"]
     *  - output: "a/b/c"
     */
    [PBStringFormatter registerTag:@"A2S" withFormatterer:^NSString *(NSString *format, id value) {
        return [value componentsJoinedByString:format];
    }];
    ```

## License

Pbind is available under the MIT license. See the LICENSE file for more info.
