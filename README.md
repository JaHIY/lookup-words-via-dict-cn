# 利用海词（dict.cn）查单词的 perl 脚本

## Environment:
 * Perl 5.10.0+
 * Required Modules:
    * [JSON](https://metacpan.org/pod/JSON)
    * [URI](https://metacpan.org/pod/URI)
    * if you want the best experience, you should install [Term::ReadLine::Gnu](https://metacpan.org/pod/Term::ReadLine::Gnu).

## How to use:
```
$ ./main.pl apple
Define apple
n.苹果, 珍宝, 家伙

Examples:
1. My uncle has an apple orchard.
   我叔叔拥有一个苹果园。
2. The apple pie and custard are delicious.
   苹果饼和软冻的味道好极了。
3. The apple trees are blossoming.
   苹果树正在开花。
4. The apple trees are fruiting early this year.
   今年苹果树很早结果。
5. I am cooking apple pies with my newly bought frying pan.
   我正在用我新买的煎锅做苹果馅饼。
6. He's a rotten apple.
   他是一个讨厌的家伙。

```
```
$ ./main.pl apple pie
Define apple pie
苹果派

Examples:
1. He went into the kitchen in search of food and wolfed down an apple pie.
   他走进厨房去找吃的，狼吞虎咽一般吃了个苹果馅饼。
2. Help yourself to this apple pie.
   请吃点苹果馅饼。
3. The apple pie and custard are delicious.
   苹果饼和软冻的味道好极了。
4. Apple pie and ice cream would be nice
   苹果派和冰淇淋就行了。

```
```
$ ./main.pl applyed
Sorry, applyed not found!
Are you looking for:
1. applied
2. apply
3. applaud
4. upload
5. applet
6. applud
7. aploid
8. dappled
9. allied
10. supplied

```
```
$ ./main.pl apple store
Sorry, apple store not found!
Are you looking for:
Sorry, word not found!

```
