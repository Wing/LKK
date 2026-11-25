// SPDX-License-Identifier: BSD-3-Clause
#include "Engine.hpp"
#include <fstream>
int main(int argc,char** argv) {
    try {
        if(argc==2 && std::string(argv[1])=="encode") {
            std::string line;
            while(std::getline(std::cin,line)) {
                std::string result;size_t start=0;
                while(start<line.size()) {auto end=line.find(' ',start);auto reading=line.substr(start,end==std::string::npos?end:end-start);
                    result+=lkk::encode(reading);if(end==std::string::npos)break;start=end+1;}
                std::cout<<result<<'\n';
            }
            return 0;
        }
        if(argc>=4 && std::string(argv[1])=="query") {
            lkk::Engine engine(argv[2],":memory:");
            for(int i=3;i<argc;++i) if(!engine.insert(lkk::encode(argv[i])))throw std::runtime_error("Reading not found");
            std::cout<<engine.text()<<'\n';return 0;
        }
        std::cerr<<"Usage: modeltool encode | modeltool query MODEL READING...\n";return 2;
    } catch(const std::exception& e) {std::cerr<<e.what()<<'\n';return 1;}
}
