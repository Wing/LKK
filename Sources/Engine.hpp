// SPDX-License-Identifier: BSD-3-Clause
#pragma once
#include "Graph.h"
#include "Mandarin.h"
#include <memory>
#include <stdexcept>

namespace lkk {
using namespace Manjusri;
using namespace Formosa::Mandarin;
inline std::string encode(const std::string& reading) {
    return BPMF::FromComposedString(reading).absoluteOrderString();
}
// Engine contexts are confined to the application main thread.
class Engine {
    std::shared_ptr<LanguageModel> model_;
    std::unique_ptr<Graph> graph_;
    std::vector<std::string> blocks_;
    size_t cursor_ = 0;
    CandidateVector candidates_;
public:
    Engine(const std::string& dictionary, const std::string& userFile) {
        static std::map<std::pair<std::string,std::string>,std::weak_ptr<LanguageModel>> sharedModels;
        auto key=std::make_pair(dictionary,userFile);
        if(userFile!=":memory:") model_=sharedModels[key].lock();
        if(model_) { graph_=std::make_unique<Graph>(model_.get()); rebuild(); return; }
        auto *db = OpenVanilla::OVSQLiteConnection::Open();
        if (!db) throw std::runtime_error("Cannot create model connection");
        sqlite3* input = nullptr;
        int result = sqlite3_open_v2(dictionary.c_str(), &input, SQLITE_OPEN_READONLY, nullptr);
        if (result != SQLITE_OK) { if(input) sqlite3_close(input); delete db; throw std::runtime_error("Cannot read dictionary"); }
        sqlite3_backup* backup = sqlite3_backup_init(db->connection(), "main", input, "main");
        if (!backup) { sqlite3_close(input); delete db; throw std::runtime_error("Cannot load dictionary"); }
        result = sqlite3_backup_step(backup, -1);
        int finish = sqlite3_backup_finish(backup);
        sqlite3_close(input);
        if (result != SQLITE_DONE || finish != SQLITE_OK) { delete db; throw std::runtime_error("Dictionary copy failed"); }
        if (!db->hasTable("unigrams") || !db->hasTable("bigrams")) { delete db; throw std::runtime_error("Unsupported dictionary schema"); }
        if (db->execute("ATTACH %Q AS userdb", userFile.c_str()) != SQLITE_OK ||
            db->execute("CREATE TABLE IF NOT EXISTS userdb.user_unigrams(qstring TEXT,current TEXT,probability REAL,backoff REAL)") != SQLITE_OK ||
            db->execute("CREATE TABLE IF NOT EXISTS userdb.user_bigram_cache(qstring TEXT,previous TEXT,current TEXT,probability REAL)") != SQLITE_OK ||
            db->execute("CREATE TABLE IF NOT EXISTS userdb.user_candidate_override_cache(qstring TEXT,current TEXT)") != SQLITE_OK) {
            delete db; throw std::runtime_error("Cannot open user storage");
        }
        model_ = std::make_shared<LanguageModel>(db, nullptr, true, false, true, true, true);
        Node::SetUNK(model_->UNKUnigram().probability, model_->UNKUnigram().backoff);
        model_->loadUserBigramCache();
        model_->loadUserCandidateOverrideCache();
        if(userFile!=":memory:") sharedModels[key]=model_;
        graph_ = std::make_unique<Graph>(model_.get());
        rebuild();
    }
    ~Engine() { save(); }
    bool save() { return model_ && model_->saveUserBigramCacheAndCandidateOverrideCache(true, true); }
    void rebuild() { candidates_.clear(); graph_->clear(); graph_->setSource(blocks_); graph_->build(); }
    std::string text() { return FastPathAsString(graph_->fastWalk()); }
    bool empty() const { return blocks_.empty(); }
    size_t cursor() const { return cursor_; }
    size_t count() const { return blocks_.size(); }
    void move(int delta) { cursor_ = delta < 0 ? (cursor_ ? cursor_-1 : 0) : std::min(blocks_.size(),cursor_+1); }
    void home() { cursor_=0; }
    void end() { cursor_=blocks_.size(); }
    bool insert(const std::string& q) {
        if (q.empty() || model_->findUnigrams(q).empty()) return false;
        blocks_.insert(blocks_.begin()+cursor_,q); ++cursor_; rebuild(); return true;
    }
    bool backspace() { if(!cursor_) return false; blocks_.erase(blocks_.begin()+--cursor_); rebuild(); return true; }
    bool forwardDelete() { if(cursor_>=blocks_.size()) return false; blocks_.erase(blocks_.begin()+cursor_); rebuild(); return true; }
    void clear() { blocks_.clear(); cursor_=0; rebuild(); }
    std::vector<std::string> candidates() {
        candidates_.clear(); if(empty()) return {};
        candidates_ = graph_->candidatesAtIndex(std::min(cursor_+1,blocks_.size()));
        std::vector<std::string> out;
        for(const auto& c : candidates_) out.push_back(c.first.first);
        return out;
    }
    bool choose(size_t index) {
        if(index>=candidates_.size()) return false;
        auto candidate=candidates_[index];
        if(!graph_->overrideNodeCandidate(*candidate.second,candidate.first.first,true)) return false;
        // Graph iterators remain valid until the next rebuild. Persist before clearing.
        candidates_.clear(); save(); return true;
    }
    bool addPhrase(const std::string& reading, const std::string& phrase) {
        if(phrase.empty() || reading.empty()) return false;
        std::string q; size_t begin=0;
        do { auto pos=reading.find('-',begin); auto syllable=reading.substr(begin,pos==std::string::npos?pos:pos-begin);
            auto b=BPMF::FromComposedString(syllable); if(b.isEmpty())return false; q+=b.absoluteOrderString();
            if(pos==std::string::npos)break;begin=pos+1;
        } while(begin<reading.size());
        auto chars=OpenVanilla::OVUTF8Helper::SplitStringByCodePoint(phrase);
        if(chars.size()*2!=q.size())return false;
        // Phrase insertion is performed through the original model's user-table API.
        bool result=model_->addUserUnigram(q,phrase); model_->flushCache(); rebuild(); return result;
    }
};
}
