// SPDX-License-Identifier: BSD-3-Clause
#include "Engine.hpp"
#include <iostream>
void check(bool condition,const char* message) {if(!condition)throw std::runtime_error(message);}
int main(int argc,char**argv) {
 try {
  check(argc==3,"fixture and user database required");
  {auto db=OpenVanilla::OVSQLiteConnection::Open(argv[1]);
   check(db!=nullptr,"open fixture");
   auto pair=lkk::encode("ㄊㄚ")+" "+lkk::encode("ㄏㄠˇ");
   check(db->execute("INSERT INTO bigrams VALUES(%Q, '他', '郝', -0.01)",pair.c_str())==SQLITE_OK,"insert synthetic bigram");delete db;
   lkk::Engine engine(argv[1],":memory:");engine.insert(lkk::encode("ㄊㄚ"));engine.insert(lkk::encode("ㄏㄠˇ"));
   check(engine.text()=="他郝","bigram changes best path");}
  { lkk::Engine engine(argv[1],argv[2]);
    check(engine.insert(lkk::encode("ㄋㄧˇ")),"insert ni");
    check(engine.insert(lkk::encode("ㄏㄠˇ")),"insert hao");
    check(engine.text()=="你好","phrase decoding");
    check(engine.backspace(),"delete final syllable");check(engine.text()=="你","delete preserves prefix");
    engine.clear();check(engine.empty(),"clear composition");
    check(engine.insert(lkk::encode("ㄊㄚ")),"ambiguous reading");
    auto values=engine.candidates();auto it=std::find(values.begin(),values.end(),"她");
    check(it!=values.end(),"alternative candidate exists");check(engine.choose(it-values.begin()),"candidate override");
    check(engine.text()=="她","selection changes result");
    check(engine.save(),"persist overrides");
    {lkk::Engine other(argv[1],argv[2]);
     check(other.insert(lkk::encode("ㄊㄚ")),"second context reading");
     check(other.text()=="她","shared preferences across contexts");
     check(other.addPhrase("ㄏㄠˇ-ㄋㄧˇ","好你"),"manual phrase insertion");
     check(!other.addPhrase("ㄏㄠˇ","好你"),"invalid reading count rejected");}
    check(engine.save(),"first context save preserves newer state");
  }
  {lkk::Engine engine(argv[1],argv[2]);check(engine.insert(lkk::encode("ㄊㄚ")),"reload reading");check(engine.text()=="她","selection survives restart");
   engine.home();check(!engine.backspace(),"front bound");check(engine.forwardDelete(),"forward delete");check(engine.empty(),"delete clears syllable");
   check(!engine.insert(lkk::encode("ㄓㄨㄥˋ")),"unknown reading is rejected without modifying composition");}
  {lkk::Engine engine(argv[1],argv[2]);
   check(engine.insert(lkk::encode("ㄏㄠˇ")),"phrase reload first reading");
   check(engine.insert(lkk::encode("ㄋㄧˇ")),"phrase reload second reading");
   check(engine.text()=="好你","manual phrase survives new model connection");}
  {lkk::Engine engine(argv[1],":memory:");
   for(int i=0;i<24;i++){check(engine.insert(lkk::encode("ㄋㄧˇ")),"long composition ni");check(engine.insert(lkk::encode("ㄏㄠˇ")),"long composition hao");}
   std::string expected;for(int i=0;i<24;i++)expected+="你好";
   check(engine.text()==expected,"long ambiguous segmentation remains correct");}
  bool rejected=false;try{lkk::Engine missing("/nonexistent/lkk-model",":memory:");}catch(...){rejected=true;}check(rejected,"missing model rejected");
  std::cout<<"Engine tests passed\n";return 0;
 }catch(const std::exception&e){std::cerr<<e.what()<<'\n';return 1;}
}
