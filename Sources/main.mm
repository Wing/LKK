// SPDX-License-Identifier: BSD-3-Clause
#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>
#include "Engine.hpp"
#include <filesystem>

static NSString *UserDirectory() {
    NSString *base=NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask,YES).firstObject;
    NSString *directory=[base stringByAppendingPathComponent:@"LKK"];
    [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:@{NSFilePosixPermissions:@0700} error:nil];
    return directory;
}
static NSString *ModelPath() {return [[NSBundle mainBundle] pathForResource:@"model" ofType:@"db"];}
static NSString *S(const std::string& value) {return [[NSString alloc] initWithBytes:value.data() length:value.size() encoding:NSUTF8StringEncoding] ?: @"";}

@interface LKKSettings : NSObject
@property NSWindow *window;
@property NSTextField *readingField;
@property NSTextField *phraseField;
@property NSTextField *status;
@property(copy) void (^addPhrase)(NSString*,NSString*);
- (void)show;
@end
@implementation LKKSettings
- (void)show {
 if(!self.window) {
  self.window=[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,440,260) styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable backing:NSBackingStoreBuffered defer:NO];
  self.window.title=@"LKK 設定";self.window.releasedWhenClosed=NO;
  NSView *v=self.window.contentView;
  NSArray *labels=@[@"LKK 輸入法 · 測試版",@"新增詞彙（注音之間使用 - 分隔）",@"注音",@"詞彙"];
  CGFloat ys[]={220,185,145,105};
  for(int i=0;i<4;i++){NSTextField*l=[NSTextField labelWithString:labels[i]];l.frame=NSMakeRect(20,ys[i],400,24);[v addSubview:l];}
  self.readingField=[[NSTextField alloc] initWithFrame:NSMakeRect(80,145,330,24)];self.readingField.placeholderString=@"ㄋㄧˇ-ㄏㄠˇ";[v addSubview:self.readingField];
  self.phraseField=[[NSTextField alloc] initWithFrame:NSMakeRect(80,105,330,24)];[v addSubview:self.phraseField];
  NSButton *b=[NSButton buttonWithTitle:@"新增詞彙" target:self action:@selector(add:)];b.frame=NSMakeRect(300,60,110,30);[v addSubview:b];
  self.status=[NSTextField labelWithString:@"標準注音；Space 選字，方向鍵翻選，Enter 送出。"];
  self.status.frame=NSMakeRect(20,15,400,35);self.status.lineBreakMode=NSLineBreakByWordWrapping;[v addSubview:self.status];
 }
 [self.window center];[NSApp activateIgnoringOtherApps:YES];[self.window makeKeyAndOrderFront:nil];
}
- (void)add:(id)sender {if(self.addPhrase)self.addPhrase(self.readingField.stringValue,self.phraseField.stringValue);}
@end

@interface LKKController : IMKInputController <NSTableViewDataSource,NSTableViewDelegate> {
 std::unique_ptr<lkk::Engine> engine;
 std::unique_ptr<Formosa::Mandarin::BopomofoReadingBuffer> reading;
 std::vector<std::string> choices;
 bool choosing;
 size_t page;

}
@property NSPanel *candidatePanel;
@property NSTableView *candidateTable;
@property LKKSettings *settings;
@property NSString *failure;
- (void)showSettings:(id)sender;
@end
@implementation LKKController
- (id)initWithServer:(IMKServer*)server delegate:(id)delegate client:(id)client {
 self=[super initWithServer:server delegate:delegate client:client];
 if(self) {
  reading=std::make_unique<Formosa::Mandarin::BopomofoReadingBuffer>(Formosa::Mandarin::BopomofoKeyboardLayout::StandardLayout());
  try {NSString*path=ModelPath();if(!path)throw std::runtime_error("Missing dictionary");
   engine=std::make_unique<lkk::Engine>(path.fileSystemRepresentation,[[UserDirectory() stringByAppendingPathComponent:@"user.sqlite3"] fileSystemRepresentation]);
  }catch(const std::exception&e){self.failure=S(e.what());}
 }
 return self;
}
- (NSUInteger)recognizedEvents:(id)sender {return NSEventMaskKeyDown;}
- (void)activateServer:(id)sender {if(self.failure)NSBeep();}
- (NSMenu*)menu {
 NSMenu*m=[[NSMenu alloc]initWithTitle:@"LKK"];
 NSMenuItem*i=[[NSMenuItem alloc]initWithTitle:@"LKK 設定…" action:@selector(showSettings:) keyEquivalent:@""];i.target=self;[m addItem:i];return m;
}
- (void)showSettings:(id)sender {
 if(!self.settings)self.settings=[LKKSettings new];
 __weak LKKController*weak=self;
 self.settings.addPhrase=^(NSString*r,NSString*p){LKKController*strong=weak;if(!strong)return;
  bool success=strong->engine && strong->engine->addPhrase(r.UTF8String,p.UTF8String);
  strong.settings.status.stringValue=success?@"詞彙已新增。":@"無法新增：請確認注音、詞長，或詞彙是否已存在。";};
 [self.settings show];
}
- (void)hideCandidates {choosing=false;choices.clear();[self.candidatePanel orderOut:nil];}
- (void)updateComposition:(id)client {
 NSString*text=S(engine->text());
 // Imported model entries are restricted to one Unicode scalar per syllable.
 auto points=OpenVanilla::OVUTF8Helper::SplitStringByCodePoint(engine->text());
 NSMutableString*prefix=[NSMutableString string];
 for(size_t i=0;i<std::min(engine->cursor(),points.size());++i)[prefix appendString:S(points[i])];
 NSUInteger offset=std::min(prefix.length,text.length);
 NSMutableString*marked=[text mutableCopy];[marked insertString:S(reading->composedString()) atIndex:offset];
 NSDictionary*a=@{NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle),NSMarkedClauseSegmentAttributeName:@0};
 NSAttributedString*value=[[NSAttributedString alloc]initWithString:marked attributes:a];
 [client setMarkedText:value selectionRange:NSMakeRange(offset+S(reading->composedString()).length,0) replacementRange:NSMakeRange(NSNotFound,NSNotFound)];
}
- (void)commit:(id)client {
 [self hideCandidates];
 NSString*value=[S(engine->text()) stringByAppendingString:S(reading->composedString())];
 if(value.length)[client insertText:value replacementRange:NSMakeRange(NSNotFound,NSNotFound)];
 engine->save();engine->clear();reading->clear();
 [client setMarkedText:@"" selectionRange:NSMakeRange(0,0) replacementRange:NSMakeRange(NSNotFound,NSNotFound)];
}
- (void)deactivateServer:(id)sender {
 if(engine){[self commit:self.client];}else [self hideCandidates];
}
- (void)commitComposition:(id)sender {if(engine)[self commit:self.client];}
- (NSInteger)numberOfRowsInTableView:(NSTableView*)table {return std::min<size_t>(9,choices.size()-std::min(choices.size(),page*9));}
- (id)tableView:(NSTableView*)table objectValueForTableColumn:(NSTableColumn*)column row:(NSInteger)row {
 size_t index=page*9+row;if(index>=choices.size())return @"";
 return [NSString stringWithFormat:@"%ld. %@",(long)row+1,S(choices[index])];
}
- (void)candidateClicked:(id)sender {NSInteger row=self.candidateTable.clickedRow;if(row>=0)[self selectChoice:page*9+row client:self.client];}
- (void)selectChoice:(size_t)index client:(id)client {
 engine->choose(index);[self hideCandidates];[self updateComposition:client];
}
- (void)showCandidates:(id)client {
 choices=engine->candidates();if(choices.empty()){NSBeep();return;}choosing=true;page=0;
 if(!self.candidatePanel){
  self.candidatePanel=[[NSPanel alloc]initWithContentRect:NSMakeRect(0,0,260,220) styleMask:NSWindowStyleMaskNonactivatingPanel|NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];
  self.candidatePanel.level=NSPopUpMenuWindowLevel;self.candidatePanel.hasShadow=YES;
  self.candidatePanel.collectionBehavior=NSWindowCollectionBehaviorCanJoinAllSpaces|NSWindowCollectionBehaviorFullScreenAuxiliary;
  self.candidateTable=[[NSTableView alloc]initWithFrame:NSMakeRect(0,0,260,220)];
  NSTableColumn*c=[[NSTableColumn alloc]initWithIdentifier:@"candidate"];c.width=250;[self.candidateTable addTableColumn:c];
  self.candidateTable.headerView=nil;self.candidateTable.rowHeight=25;self.candidateTable.dataSource=self;self.candidateTable.delegate=self;
  self.candidateTable.target=self;self.candidateTable.action=@selector(candidateClicked:);self.candidatePanel.contentView=self.candidateTable;
 }
 [self.candidateTable reloadData];[self.candidateTable selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
 NSRect caret=NSZeroRect;
 @try{[client attributesForCharacterIndex:0 lineHeightRectangle:&caret];}@catch(NSException*e){}
 NSScreen*screen=NSScreen.mainScreen;
 for(NSScreen*s in NSScreen.screens)if(NSIntersectsRect(s.frame,caret)){screen=s;break;}
 NSRect visible=screen.visibleFrame;
 CGFloat height=std::min<size_t>(9,choices.size())*25+8;
 CGFloat x=MAX(NSMinX(visible),MIN(caret.origin.x,NSMaxX(visible)-260));
 CGFloat y=caret.origin.y-height-4;if(y<NSMinY(visible))y=NSMaxY(caret)+4;
 y=MAX(NSMinY(visible),MIN(y,NSMaxY(visible)-height));
 [self.candidatePanel setFrame:NSMakeRect(x,y,260,height) display:YES];[self.candidatePanel orderFront:nil];
}
- (BOOL)handleEvent:(NSEvent*)event client:(id)client {
 if(event.type!=NSEventTypeKeyDown || !engine)return NO;
 NSString*chars=event.charactersIgnoringModifiers ?: @"";
 unsigned short code=event.keyCode;
 NSEventModifierFlags flags=event.modifierFlags;
 if(flags&(NSEventModifierFlagCommand|NSEventModifierFlagControl|NSEventModifierFlagOption)){
  if(!engine->empty() || !reading->isEmpty())[self commit:client];return NO;
 }
 if(flags&NSEventModifierFlagCapsLock){if(!engine->empty()||!reading->isEmpty())[self commit:client];return NO;}
 if(choosing){
  if(code==53){[self hideCandidates];return YES;}
  if(chars.length==1 && [chars characterAtIndex:0]>='1' && [chars characterAtIndex:0]<='9'){
   size_t index=page*9+[chars characterAtIndex:0]-'1';if(index<choices.size())[self selectChoice:index client:client];else NSBeep();return YES;}
  if(code==36){NSInteger row=self.candidateTable.selectedRow;[self selectChoice:page*9+MAX(0,row) client:client];return YES;}
  if(code==49||code==121||code==124){page=(page+1)%((choices.size()+8)/9);[self.candidateTable reloadData];[self.candidateTable selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];return YES;}
  if(code==116||code==123){page=page?page-1:(choices.size()-1)/9;[self.candidateTable reloadData];return YES;}
  if(code==125||code==126){NSInteger row=self.candidateTable.selectedRow+(code==125?1:-1);NSInteger count=[self numberOfRowsInTableView:self.candidateTable];row=(row+count)%count;[self.candidateTable selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];return YES;}
  [self hideCandidates];
 }
 if(code==53){if(reading->isEmpty()&&engine->empty())return NO;reading->clear();engine->clear();[self updateComposition:client];return YES;}
 if(code==51){if(!reading->isEmpty())reading->backspace();else if(!engine->backspace())return NO;[self updateComposition:client];return YES;}
 if(code==117){if(!reading->isEmpty()){reading->clear();}else if(!engine->forwardDelete())return NO;[self updateComposition:client];return YES;}
 if(code==36){if(engine->empty()&&reading->isEmpty())return NO;[self commit:client];return YES;}
 if((code==123||code==124||code==115||code==119)&&reading->isEmpty()&&!engine->empty()){
  if(code==115)engine->home();else if(code==119)engine->end();else engine->move(code==123?-1:1);[self updateComposition:client];return YES;}
 if((code==49||code==125)&&reading->isEmpty()&&!engine->empty()){[self showCandidates:client];return YES;}
 if(chars.length==1 && !(flags&NSEventModifierFlagShift)){
  char key=(char)[chars characterAtIndex:0];
  if(reading->isValidKey(key) || (code==49&&!reading->isEmpty())){
   if(code!=49)reading->combineKey(key);
   if(reading->hasToneMarker()||code==49){
    if(!engine->insert(reading->syllable().absoluteOrderString())){NSBeep();[self updateComposition:client];return YES;}
    reading->clear();
   }
   [self updateComposition:client];return YES;
  }
 }
 // Punctuation and shifted ASCII are literal passthrough, after committing composition.
 if(!engine->empty()||!reading->isEmpty())[self commit:client];
 return NO;
}
@end

int main(int argc,char**argv){
 @autoreleasepool {
  if(argc==2 && strcmp(argv[1],"--check-model")==0){
   try{NSString*p=ModelPath();if(!p)return 1;lkk::Engine e(p.fileSystemRepresentation,":memory:");
    if(!e.insert(lkk::encode("ㄋㄧˇ"))||!e.insert(lkk::encode("ㄏㄠˇ")))return 1;
    std::cout<<e.text()<<"\n";return e.text().empty();
   }catch(const std::exception&e){std::cerr<<e.what()<<'\n';return 1;}
  }
  [NSApplication sharedApplication];
  IMKServer*server=[[IMKServer alloc]initWithName:@"LKK_Connection" bundleIdentifier:NSBundle.mainBundle.bundleIdentifier];
  if(!server)return 1;
  [NSApp run];(void)server;
 }
 return 0;
}
