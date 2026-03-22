import Foundation

/// Splits a continuous Pinyin string into valid Mandarin syllables.
///
/// Example:  "nihaowoshizhongguoren"
///        → ["ni","hao","wo","shi","zhong","guo","ren"]
///
/// Uses greedy longest-match left-to-right over the 412 known syllables.
/// Ambiguous parses (xian = xi+an vs xian) prefer the longer syllable, which
/// matches standard Mandarin romanisation in the vast majority of cases.
enum PinyinSegmenter {

    /// Returns the syllable list for `buffer`.
    /// Trailing chars that don't yet form a complete syllable are returned as
    /// a single partial string at the end (so callers can detect in-progress input).
    static func segment(_ buffer: String) -> [String] {
        let buf = buffer.lowercased()
        var result: [String] = []
        var idx = buf.startIndex

        while idx < buf.endIndex {
            let remaining = buf.distance(from: idx, to: buf.endIndex)
            var matched = false

            // Try longest possible syllable first (max 6 chars)
            for len in stride(from: min(6, remaining), through: 1, by: -1) {
                let end = buf.index(idx, offsetBy: len)
                let candidate = String(buf[idx..<end])
                if validSyllables.contains(candidate) {
                    result.append(candidate)
                    idx = end
                    matched = true
                    break
                }
            }

            if !matched {
                // Partial / unrecognised — treat as one chunk (user still typing)
                result.append(String(buf[idx...]))
                break
            }
        }
        return result
    }

    /// Returns true if every character in `buffer` has been consumed into
    /// complete, recognisable syllables (no partial tail).
    static func isComplete(_ buffer: String) -> Bool {
        let segs = segment(buffer)
        return segs.allSatisfy { validSyllables.contains($0) }
    }

    // MARK: - 412 valid Mandarin syllables (derived from Google PinyinIME rawdict)

    static let validSyllables: Set<String> = [
        "chuang", "shuang", "zhuang",
        "chang", "cheng", "chong", "chuai", "chuan",
        "guang", "huang", "jiang", "jiong", "kuang", "liang",
        "niang", "qiang", "qiong", "shang", "sheng", "shuai",
        "shuan", "xiang", "xiong", "zhang", "zheng", "zhong",
        "zhuai", "zhuan",
        "bang", "beng", "bian", "biao", "bing",
        "cang", "ceng", "chai", "chan", "chao", "chen", "chou",
        "chui", "chun", "chuo", "cong", "cuan",
        "dang", "deng", "dian", "diao", "ding", "dong", "duan",
        "fang", "feng",
        "gang", "geng", "gong", "guai", "guan",
        "hang", "heng", "hong", "huai", "huan",
        "jian", "jiao", "jing", "juan",
        "kang", "keng", "kong", "kuai", "kuan",
        "lang", "leng", "lian", "liao", "ling", "long", "luan",
        "mang", "meng", "mian", "miao", "ming",
        "nang", "neng", "nian", "niao", "ning", "nong", "nuan",
        "pang", "peng", "pian", "piao", "ping",
        "qian", "qiao", "qing", "quan",
        "rang", "reng", "rong", "ruan",
        "sang", "seng", "shai", "shan", "shao", "shei", "shen",
        "shou", "shua", "shui", "shun", "shuo", "song", "suan",
        "tang", "teng", "tian", "tiao", "ting", "tong", "tuan",
        "wang", "weng",
        "xian", "xiao", "xing", "xuan",
        "yang", "ying", "yong", "yuan",
        "zang", "zeng", "zhai", "zhan", "zhao", "zhei", "zhen",
        "zhou", "zhua", "zhui", "zhun", "zhuo", "zong", "zuan",
        "ang",
        "bai", "ban", "bao", "bei", "ben", "bie", "bin",
        "cai", "can", "cao", "cen", "cha", "che", "chi",
        "chu", "cou", "cui", "cun", "cuo",
        "dai", "dan", "dao", "dei", "den", "dia", "die",
        "diu", "dou", "dui", "dun", "duo",
        "eng",
        "fan", "fei", "fen", "fou",
        "gai", "gan", "gao", "gei", "gen", "gou", "gua",
        "gui", "gun", "guo",
        "hai", "han", "hao", "hei", "hen", "hou", "hua",
        "hui", "hun", "huo",
        "jia", "jie", "jin", "jiu", "jue", "jun",
        "kai", "kan", "kao", "kei", "ken", "kou", "kua",
        "kui", "kun", "kuo",
        "lai", "lan", "lao", "lei", "lia", "lie", "lin",
        "liu", "lou", "lue", "lun", "luo",
        "mai", "man", "mao", "mei", "men", "mie", "min",
        "miu", "mou",
        "nai", "nan", "nao", "nei", "nen", "nie", "nin",
        "niu", "nou", "nue", "nuo",
        "pai", "pan", "pao", "pei", "pen", "pie", "pin", "pou",
        "qia", "qie", "qin", "qiu", "que", "qun",
        "ran", "rao", "ren", "rou", "rui", "run", "ruo",
        "sai", "san", "sao", "sen", "sha", "she", "shi",
        "shu", "sou", "sui", "sun", "suo",
        "tai", "tan", "tao", "tei", "tie", "tou", "tui",
        "tun", "tuo",
        "wai", "wan", "wei", "wen",
        "xia", "xie", "xin", "xiu", "xue", "xun",
        "yan", "yao", "yin", "you", "yue", "yun",
        "zai", "zan", "zao", "zei", "zen", "zha", "zhe",
        "zhi", "zhu", "zou", "zui", "zun", "zuo",
        "ai", "an", "ao",
        "ba", "bi", "bo", "bu",
        "ca", "ce", "ci", "cu",
        "da", "de", "di", "du",
        "ei", "en", "er",
        "fa", "fo", "fu",
        "ga", "ge", "gu",
        "ha", "he", "hu",
        "ji", "ju",
        "ka", "ke", "ku",
        "la", "le", "li", "lo", "lu", "lv",
        "ma", "me", "mi", "mo", "mu",
        "na", "ne", "ng", "ni", "nu", "nv",
        "ou",
        "pa", "pi", "po", "pu",
        "qi", "qu",
        "re", "ri", "ru",
        "sa", "se", "si", "su",
        "ta", "te", "ti", "tu",
        "wa", "wo", "wu",
        "xi", "xu",
        "ya", "ye", "yi", "yo", "yu",
        "za", "ze", "zi", "zu",
        "a", "e", "m", "n", "o",
    ]
}
