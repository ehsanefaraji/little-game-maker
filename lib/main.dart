import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const purple=Color(0xFF7657D5), pageBg=Color(0xFFF7F4FF);
enum Kind{maze,platformer,memory,driving}
extension KindInfo on Kind{
 String get title=>switch(this){Kind.maze=>'هزارتو',Kind.platformer=>'سکوبازی',Kind.memory=>'حافظه',Kind.driving=>'رانندگی'};
 IconData get icon=>switch(this){Kind.maze=>Icons.route,Kind.platformer=>Icons.sports_esports,Kind.memory=>Icons.extension,Kind.driving=>Icons.directions_car};
 String get hint=>switch(this){Kind.maze=>'راهت را تا گنج پیدا کن',Kind.platformer=>'از موانع بپر',Kind.memory=>'جفت کارت‌ها را پیدا کن',Kind.driving=>'از موانع دوری کن'};
}
class Project{
 Project({required this.id,required this.name,required this.kind,required this.cells});
 final String id; String name; Kind kind; List<int> cells;
 Project copy()=>Project(id:id,name:name,kind:kind,cells:List<int>.from(cells));
 Map<String,dynamic> json()=>{'id':id,'name':name,'kind':kind.name,'cells':cells};
 factory Project.read(Map<String,dynamic> j)=>Project(id:j['id']??'',name:j['name']??'بازی من',kind:Kind.values.firstWhere((e)=>e.name==j['kind'],orElse:()=>Kind.maze),cells:(j['cells'] as List).cast<int>());
 static Project make(Kind k,String n){
  final c=List<int>.filled(64,0);
  if(k==Kind.maze){for(final i in [9,10,11,19,27,28,29,37,45,46,53]){c[i]=1;}c[63]=2;}
  if(k==Kind.platformer){for(final i in [13,22,31,40,49]){c[i]=3;}for(final i in [18,26,34,42,50]){c[i]=4;}c[7]=2;}
  if(k==Kind.memory){for(var i=0;i<16;i++){c[i]=i%8+1;}}
  if(k==Kind.driving){for(final i in [2,5,11,14,18,21,27,30,34,37,43,46,50,53]){c[i]=4;}}
  return Project(id:DateTime.now().microsecondsSinceEpoch.toString(),name:n,kind:k,cells:c);
 }
}
class Store{
 static const key='lgm_projects_v1';
 static Future<List<Project>> load()async{final p=await SharedPreferences.getInstance();final s=p.getString(key);if(s==null)return[];try{return(jsonDecode(s) as List).map((e)=>Project.read(e)).toList();}catch(_){return[];}}
 static Future<void> save(List<Project> a)async{final p=await SharedPreferences.getInstance();await p.setString(key,jsonEncode(a.map((e)=>e.json()).toList()));}
}
void main()=>runApp(const App());
class App extends StatelessWidget{const App({super.key});@override Widget build(BuildContext c)=>MaterialApp(debugShowCheckedModeBanner:false,title:'بازی‌ساز کوچولو',theme:ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:purple),scaffoldBackgroundColor:pageBg),home:const Home());}
class Home extends StatefulWidget{const Home({super.key});@override State<Home> createState()=>_HomeState();}
class _HomeState extends State<Home>{
 List<Project> projects=[];bool busy=true;
 @override void initState(){super.initState();refresh();}
 Future<void> refresh()async{final a=await Store.load();if(mounted)setState((){projects=a;busy=false;});}
 Future<void> edit(Project p)async{await Navigator.push(context,MaterialPageRoute(builder:(_)=>Editor(project:p.copy())));await refresh();}
 Future<void> create(Kind k)async{final ctl=TextEditingController(text:'بازی '+k.title+' من');final n=await showDialog<String>(context:context,builder:(d)=>AlertDialog(title:Text('ساخت بازی '+k.title),content:TextField(controller:ctl,decoration:const InputDecoration(labelText:'نام بازی')),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('لغو')),FilledButton(onPressed:()=>Navigator.pop(d,ctl.text),child:const Text('شروع'))]));ctl.dispose();if(n!=null)await edit(Project.make(k,n.trim().isEmpty?'بازی جدید':n.trim()));}
 Future<void> remove(Project p)async{projects.removeWhere((e)=>e.id==p.id);await Store.save(projects);if(mounted)setState((){});}
 @override Widget build(BuildContext c)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('بازی‌ساز کوچولو 🎮')),body:busy?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(16),children:[
  Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF9C83F5),Color(0xFF6D55C7)]),borderRadius:BorderRadius.circular(24)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('سلام قهرمان!',style:TextStyle(color:Colors.white,fontSize:25,fontWeight:FontWeight.bold)),SizedBox(height:8),Text('قالب بازی را انتخاب کن، مرحله‌ات را بساز و بازی کن.',style:TextStyle(color:Colors.white,fontSize:15))])),
  const SizedBox(height:18),const Text('ساخت بازی جدید',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:10),
  GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,childAspectRatio:1.5,crossAxisSpacing:10,mainAxisSpacing:10,children:Kind.values.map((k)=>InkWell(onTap:()=>create(k),borderRadius:BorderRadius.circular(18),child:Ink(decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18)),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(k.icon,color:purple,size:34),Text(k.title,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:16)),Text(k.hint,style:const TextStyle(fontSize:11))])))).toList()),
  const SizedBox(height:22),Text('بازی‌های من ('+projects.length.toString()+')',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
  if(projects.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(20),child:Text('هنوز بازی نساختی؛ یکی از قالب‌ها را انتخاب کن.')))
  else ...projects.map((p)=>Card(color:Colors.white,child:ListTile(leading:Icon(p.kind.icon,color:purple),title:Text(p.name),subtitle:Text(p.kind.title),onTap:()=>edit(p),trailing:PopupMenuButton<String>(onSelected:(v){if(v=='edit')edit(p);if(v=='play')Navigator.push(context,MaterialPageRoute(builder:(_)=>Play(project:p.copy())));if(v=='delete')remove(p);},itemBuilder:(_)=>const[PopupMenuItem(value:'play',child:Text('بازی کن')),PopupMenuItem(value:'edit',child:Text('ویرایش')),PopupMenuItem(value:'delete',child:Text('حذف'))])))),
  const SizedBox(height:12),const Center(child:Text('ذخیره آفلاین روی همین دستگاه',style:TextStyle(color:Colors.black54)))
 ])));
}
Color tileColor(int t)=>switch(t){1=>const Color(0xFF8B79C9),2=>const Color(0xFFFFF0B3),3=>const Color(0xFFD9F4D4),4=>const Color(0xFFFFD9D9),5=>const Color(0xFFD6EDFF),_=>Colors.white};
String face(int t)=>switch(t){1=>'🧱',2=>'⭐',3=>'🪙',4=>'🔥',5=>'🌳',6=>'🐱',7=>'🐸',8=>'🦊',_=>''};
String toolName(int t)=>switch(t){1=>'دیوار',2=>'ستاره',3=>'سکه',4=>'مانع',5=>'درخت',6=>'گربه',7=>'قورباغه',8=>'روباه',_=>'پاک‌کن'};
class Editor extends StatefulWidget{const Editor({super.key,required this.project});final Project project;@override State<Editor> createState()=>_EditorState();}
class _EditorState extends State<Editor>{
 late Project p;int selected=1;bool saving=false;
 @override void initState(){super.initState();p=widget.project;if(p.cells.length!=64)p.cells=List<int>.filled(64,0);}
 List<int> get palette=>switch(p.kind){Kind.maze=>[0,1,2,3],Kind.platformer=>[0,2,3,4,5],Kind.memory=>[0,1,2,3,4,5,6,7,8],Kind.driving=>[0,2,3,4,5]};
 Future<void> save()async{setState(()=>saving=true);final a=await Store.load();final i=a.indexWhere((e)=>e.id==p.id);if(i<0){a.insert(0,p.copy());}else{a[i]=p.copy();}await Store.save(a);if(mounted){setState(()=>saving=false);ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('بازی ذخیره شد ⭐')));}}
 Widget chip(int t)=>Container(padding:const EdgeInsets.all(9),decoration:BoxDecoration(color:selected==t?const Color(0xFFE9E1FF):const Color(0xFFF7F5FC),borderRadius:BorderRadius.circular(12),border:Border.all(color:selected==t?purple:Colors.black12,width:selected==t?2:1)),child:Column(children:[Text(face(t),style:const TextStyle(fontSize:21)),Text(toolName(t),style:const TextStyle(fontSize:11))]));
 @override Widget build(BuildContext c)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:Text(p.name),actions:[IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>Play(project:p.copy()))),icon:const Icon(Icons.play_arrow)),IconButton(onPressed:saving?null:save,icon:const Icon(Icons.save))]),body:SafeArea(child:Column(children:[
  const Padding(padding:EdgeInsets.all(10),child:Text('قطعه را انتخاب کن و روی خانه‌ها بگذار؛ می‌توانی آن را بکشانی.',textAlign:TextAlign.center)),
  Expanded(child:Center(child:AspectRatio(aspectRatio:1,child:Padding(padding:const EdgeInsets.all(10),child:GridView.builder(physics:const NeverScrollableScrollPhysics(),itemCount:64,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:8,crossAxisSpacing:3,mainAxisSpacing:3),itemBuilder:(ctx,i)=>DragTarget<int>(onAcceptWithDetails:(d)=>setState(()=>p.cells[i]=d.data),builder:(ctx,can,no)=>GestureDetector(onTap:()=>setState(()=>p.cells[i]=selected),child:Container(decoration:BoxDecoration(color:can.isNotEmpty?Colors.amber:tileColor(p.cells[i]),borderRadius:BorderRadius.circular(6),border:Border.all(color:Colors.black12)),child:Center(child:Text(face(p.cells[i]),style:const TextStyle(fontSize:19))))))))))),
  Container(color:Colors.white,padding:const EdgeInsets.all(12),child:Column(children:[const Align(alignment:Alignment.centerRight,child:Text('جعبه ابزار',style:TextStyle(fontWeight:FontWeight.bold))),const SizedBox(height:8),Wrap(spacing:7,runSpacing:7,children:palette.map((t)=>Draggable<int>(data:t,feedback:Material(color:Colors.transparent,child:chip(t)),child:InkWell(onTap:()=>setState(()=>selected=t),child:chip(t)))).toList()),const SizedBox(height:10),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>Play(project:p.copy()))),icon:const Icon(Icons.play_arrow),label:const Text('امتحان بازی')))]))
 ]))));
}
class Play extends StatefulWidget{const Play({super.key,required this.project});final Project project;@override State<Play> createState()=>_PlayState();}
class _PlayState extends State<Play>{
 late List<int> cells;int pos=0,moves=0,score=0,lane=1;final Set<int> shown={};int? first;bool lock=false;
 @override void initState(){super.initState();cells=List<int>.from(widget.project.cells);if(widget.project.kind==Kind.memory)cells=cells.take(16).toList();}
 void move(int d){final n=pos+d;if(n<0||n>=64)return;if((d==1||d==-1)&&pos~/8!=n~/8)return;if(cells[n]==1)return;setState((){pos=n;moves++;if(cells[n]==2)score++;});if(cells[n]==2)_win('ستاره را پیدا کردی!');}
 void _win(String s){showDialog<void>(context:context,builder:(d)=>AlertDialog(title:const Text('آفرین! 🏆'),content:Text(s),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('ادامه'))]));}
 void flip(int i){if(lock||shown.contains(i))return;setState(()=>shown.add(i));if(first==null){first=i;return;}final a=first!;if(cells[a]==cells[i]){first=null;score++;if(shown.length==16)_win('همه جفت‌ها را پیدا کردی!');}else{lock=true;Future.delayed(const Duration(milliseconds:650),(){if(mounted)setState((){shown.remove(a);shown.remove(i);first=null;lock=false;});});}}
 @override Widget build(BuildContext c){final k=widget.project.kind;return Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:Text(widget.project.name)),body:Padding(padding:const EdgeInsets.all(16),child:Column(children:[
  Text(k==Kind.memory?'جفت کارت‌ها را پیدا کن':k==Kind.driving?'از موانع دوری کن':k==Kind.platformer?'بپر و سکه بگیر':'به ستاره برس',style:const TextStyle(fontSize:21,fontWeight:FontWeight.bold)),
  Text('امتیاز: '+score.toString()+'   حرکت: '+moves.toString()),const SizedBox(height:12),Expanded(child:k==Kind.memory?_memory():_grid()),
  if(k==Kind.maze)Wrap(spacing:8,children:[IconButton.filled(onPressed:()=>move(-8),icon:const Icon(Icons.keyboard_arrow_up)),IconButton.filled(onPressed:()=>move(8),icon:const Icon(Icons.keyboard_arrow_down)),IconButton.filled(onPressed:()=>move(-1),icon:const Icon(Icons.keyboard_arrow_right)),IconButton.filled(onPressed:()=>move(1),icon:const Icon(Icons.keyboard_arrow_left))]),
  if(k==Kind.platformer)FilledButton(onPressed:(){setState((){moves++;score++;});if(score>=10)_win('ده ستاره جمع کردی!');},child:const Text('بپر!')),
  if(k==Kind.driving)Row(mainAxisAlignment:MainAxisAlignment.center,children:[IconButton.filled(onPressed:()=>setState(()=>lane=(lane-1).clamp(0,2).toInt()),icon:const Icon(Icons.arrow_back)),FilledButton(onPressed:(){setState(()=>score++);if(score>=10)_win('راننده قهرمان!');},child:const Text('گاز بده')),IconButton.filled(onPressed:()=>setState(()=>lane=(lane+1).clamp(0,2).toInt()),icon:const Icon(Icons.arrow_forward))])
 ]))));}
 Widget _memory()=>GridView.builder(itemCount:16,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:4,crossAxisSpacing:8,mainAxisSpacing:8),itemBuilder:(c,i)=>InkWell(onTap:()=>flip(i),child:Container decoration:BoxDecoration(color:shown.contains(i)?Colors.amber.shade100:purple,borderRadius:BorderRadius.circular(12)),child:Center(child:Text(shown.contains(i)?face(cells[i]):'❔',style:const TextStyle(fontSize:28))))));
 Widget _grid()=>AspectRatio(aspectRatio:1,child:GridView.builder(physics:const NeverScrollableScrollPhysics(),itemCount:64,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:8,crossAxisSpacing:3,mainAxisSpacing:3),itemBuilder:(c,i)=>InkWell(onTap:kTap(i),child:Container(decoration:BoxDecoration(color:i==pos?Colors.amber:tileColor(cells[i]),borderRadius:BorderRadius.circular(6)),child:Center(child:Text(i==pos?'🧒':face(cells[i])))))));
 VoidCallback? kTap(int i)=>widget.project.kind==Kind.maze?(){if((i-pos).abs()==1&&i~/8==pos~/8||(i-pos).abs()==8)move(i-pos);}:null;
}