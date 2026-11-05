import MemePuzzleCore
import SwiftUI
import UIKit

/// A bundled meme: artwork and optional overlay caption.
public struct MemeTemplate: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let resourceName: String
    public let topText: String
    public let bottomText: String

    public var category: String {
        if id.starts(with: "easy") { return "Easy" }
        if id.starts(with: "medium") { return "Medium" }
        if id.starts(with: "hard") { return "Hard" }
        if id.starts(with: "extreme") { return "Extreme" }
        return "Meme"
    }

    public var difficultyMode: DifficultyMode {
        if id.starts(with: "easy") { return .easy }
        if id.starts(with: "medium") { return .medium }
        if id.starts(with: "hard") { return .hard }
        if id.starts(with: "extreme") { return .extreme }
        return .easy
    }

    public var itemNumber: String {
        if let num = id.split(separator: "_").last {
            return "#\(num)"
        }
        return "#\(id)"
    }

    public var displayTitle: String {
        let lower = title.lowercased()
        if lower.contains("easy meme") || lower.contains("medium meme") || lower.contains("hard meme") || lower.contains("extreme meme") {
            if let num = id.split(separator: "_").last {
                return "Meme #\(num)"
            }
        }
        return title
    }

    public init(id: String, title: String, resourceName: String, topText: String = "", bottomText: String = "") {
        self.id = id
        self.title = title
        self.resourceName = resourceName
        self.topText = topText
        self.bottomText = bottomText
    }
}

public enum MemeCatalog {
    /// All 215 curated Easy Mode memes (renamed from 'memes funny with text fotos 1_1').
    /// All 169 curated Easy Mode memes (clean AI animal funny memes).
    public static let easy: [MemeTemplate] = [
        MemeTemplate(id: "easy_001", title: "Easy Meme 1", resourceName: "easy_001"),
        MemeTemplate(id: "easy_002", title: "Easy Meme 2", resourceName: "easy_002"),
        MemeTemplate(id: "easy_003", title: "Easy Meme 3", resourceName: "easy_003"),
        MemeTemplate(id: "easy_004", title: "Easy Meme 4", resourceName: "easy_004"),
        MemeTemplate(id: "easy_005", title: "Easy Meme 5", resourceName: "easy_005"),
        MemeTemplate(id: "easy_006", title: "Easy Meme 6", resourceName: "easy_006"),
        MemeTemplate(id: "easy_007", title: "Easy Meme 7", resourceName: "easy_007"),
        MemeTemplate(id: "easy_008", title: "Easy Meme 8", resourceName: "easy_008"),
        MemeTemplate(id: "easy_009", title: "Easy Meme 9", resourceName: "easy_009"),
        MemeTemplate(id: "easy_010", title: "Easy Meme 10", resourceName: "easy_010"),
        MemeTemplate(id: "easy_011", title: "Easy Meme 11", resourceName: "easy_011"),
        MemeTemplate(id: "easy_012", title: "Easy Meme 12", resourceName: "easy_012"),
        MemeTemplate(id: "easy_013", title: "Easy Meme 13", resourceName: "easy_013"),
        MemeTemplate(id: "easy_014", title: "Easy Meme 14", resourceName: "easy_014"),
        MemeTemplate(id: "easy_015", title: "Easy Meme 15", resourceName: "easy_015"),
        MemeTemplate(id: "easy_016", title: "Easy Meme 16", resourceName: "easy_016"),
        MemeTemplate(id: "easy_017", title: "Easy Meme 17", resourceName: "easy_017"),
        MemeTemplate(id: "easy_018", title: "Easy Meme 18", resourceName: "easy_018"),
        MemeTemplate(id: "easy_019", title: "Easy Meme 19", resourceName: "easy_019"),
        MemeTemplate(id: "easy_020", title: "Easy Meme 20", resourceName: "easy_020"),
        MemeTemplate(id: "easy_021", title: "Easy Meme 21", resourceName: "easy_021"),
        MemeTemplate(id: "easy_022", title: "Easy Meme 22", resourceName: "easy_022"),
        MemeTemplate(id: "easy_023", title: "Easy Meme 23", resourceName: "easy_023"),
        MemeTemplate(id: "easy_024", title: "Easy Meme 24", resourceName: "easy_024"),
        MemeTemplate(id: "easy_025", title: "Easy Meme 25", resourceName: "easy_025"),
        MemeTemplate(id: "easy_026", title: "Easy Meme 26", resourceName: "easy_026"),
        MemeTemplate(id: "easy_027", title: "Easy Meme 27", resourceName: "easy_027"),
        MemeTemplate(id: "easy_028", title: "Easy Meme 28", resourceName: "easy_028"),
        MemeTemplate(id: "easy_029", title: "Easy Meme 29", resourceName: "easy_029"),
        MemeTemplate(id: "easy_030", title: "Easy Meme 30", resourceName: "easy_030"),
        MemeTemplate(id: "easy_031", title: "Easy Meme 31", resourceName: "easy_031"),
        MemeTemplate(id: "easy_032", title: "Easy Meme 32", resourceName: "easy_032"),
        MemeTemplate(id: "easy_033", title: "Easy Meme 33", resourceName: "easy_033"),
        MemeTemplate(id: "easy_034", title: "Easy Meme 34", resourceName: "easy_034"),
        MemeTemplate(id: "easy_035", title: "Easy Meme 35", resourceName: "easy_035"),
        MemeTemplate(id: "easy_036", title: "Easy Meme 36", resourceName: "easy_036"),
        MemeTemplate(id: "easy_037", title: "Easy Meme 37", resourceName: "easy_037"),
        MemeTemplate(id: "easy_038", title: "Easy Meme 38", resourceName: "easy_038"),
        MemeTemplate(id: "easy_039", title: "Easy Meme 39", resourceName: "easy_039"),
        MemeTemplate(id: "easy_040", title: "Easy Meme 40", resourceName: "easy_040"),
        MemeTemplate(id: "easy_041", title: "Easy Meme 41", resourceName: "easy_041"),
        MemeTemplate(id: "easy_042", title: "Easy Meme 42", resourceName: "easy_042"),
        MemeTemplate(id: "easy_043", title: "Easy Meme 43", resourceName: "easy_043"),
        MemeTemplate(id: "easy_044", title: "Easy Meme 44", resourceName: "easy_044"),
        MemeTemplate(id: "easy_045", title: "Easy Meme 45", resourceName: "easy_045"),
        MemeTemplate(id: "easy_046", title: "Easy Meme 46", resourceName: "easy_046"),
        MemeTemplate(id: "easy_047", title: "Easy Meme 47", resourceName: "easy_047"),
        MemeTemplate(id: "easy_048", title: "Easy Meme 48", resourceName: "easy_048"),
        MemeTemplate(id: "easy_049", title: "Easy Meme 49", resourceName: "easy_049"),
        MemeTemplate(id: "easy_050", title: "Easy Meme 50", resourceName: "easy_050"),
        MemeTemplate(id: "easy_051", title: "Easy Meme 51", resourceName: "easy_051"),
        MemeTemplate(id: "easy_052", title: "Easy Meme 52", resourceName: "easy_052"),
        MemeTemplate(id: "easy_053", title: "Easy Meme 53", resourceName: "easy_053"),
        MemeTemplate(id: "easy_054", title: "Easy Meme 54", resourceName: "easy_054"),
        MemeTemplate(id: "easy_055", title: "Easy Meme 55", resourceName: "easy_055"),
        MemeTemplate(id: "easy_056", title: "Easy Meme 56", resourceName: "easy_056"),
        MemeTemplate(id: "easy_057", title: "Easy Meme 57", resourceName: "easy_057"),
        MemeTemplate(id: "easy_058", title: "Easy Meme 58", resourceName: "easy_058"),
        MemeTemplate(id: "easy_059", title: "Easy Meme 59", resourceName: "easy_059"),
        MemeTemplate(id: "easy_060", title: "Easy Meme 60", resourceName: "easy_060"),
        MemeTemplate(id: "easy_061", title: "Easy Meme 61", resourceName: "easy_061"),
        MemeTemplate(id: "easy_062", title: "Easy Meme 62", resourceName: "easy_062"),
        MemeTemplate(id: "easy_063", title: "Easy Meme 63", resourceName: "easy_063"),
        MemeTemplate(id: "easy_064", title: "Easy Meme 64", resourceName: "easy_064"),
        MemeTemplate(id: "easy_065", title: "Easy Meme 65", resourceName: "easy_065"),
        MemeTemplate(id: "easy_066", title: "Easy Meme 66", resourceName: "easy_066"),
        MemeTemplate(id: "easy_067", title: "Easy Meme 67", resourceName: "easy_067"),
        MemeTemplate(id: "easy_068", title: "Easy Meme 68", resourceName: "easy_068"),
        MemeTemplate(id: "easy_069", title: "Easy Meme 69", resourceName: "easy_069"),
        MemeTemplate(id: "easy_070", title: "Easy Meme 70", resourceName: "easy_070"),
        MemeTemplate(id: "easy_071", title: "Easy Meme 71", resourceName: "easy_071"),
        MemeTemplate(id: "easy_072", title: "Easy Meme 72", resourceName: "easy_072"),
        MemeTemplate(id: "easy_073", title: "Easy Meme 73", resourceName: "easy_073"),
        MemeTemplate(id: "easy_074", title: "Easy Meme 74", resourceName: "easy_074"),
        MemeTemplate(id: "easy_075", title: "Easy Meme 75", resourceName: "easy_075"),
        MemeTemplate(id: "easy_076", title: "Easy Meme 76", resourceName: "easy_076"),
        MemeTemplate(id: "easy_077", title: "Easy Meme 77", resourceName: "easy_077"),
        MemeTemplate(id: "easy_078", title: "Easy Meme 78", resourceName: "easy_078"),
        MemeTemplate(id: "easy_079", title: "Easy Meme 79", resourceName: "easy_079"),
        MemeTemplate(id: "easy_080", title: "Easy Meme 80", resourceName: "easy_080"),
        MemeTemplate(id: "easy_081", title: "Easy Meme 81", resourceName: "easy_081"),
        MemeTemplate(id: "easy_082", title: "Easy Meme 82", resourceName: "easy_082"),
        MemeTemplate(id: "easy_083", title: "Easy Meme 83", resourceName: "easy_083"),
        MemeTemplate(id: "easy_084", title: "Easy Meme 84", resourceName: "easy_084"),
        MemeTemplate(id: "easy_085", title: "Easy Meme 85", resourceName: "easy_085"),
        MemeTemplate(id: "easy_086", title: "Easy Meme 86", resourceName: "easy_086"),
        MemeTemplate(id: "easy_087", title: "Easy Meme 87", resourceName: "easy_087"),
        MemeTemplate(id: "easy_088", title: "Easy Meme 88", resourceName: "easy_088"),
        MemeTemplate(id: "easy_089", title: "Easy Meme 89", resourceName: "easy_089"),
        MemeTemplate(id: "easy_090", title: "Easy Meme 90", resourceName: "easy_090"),
        MemeTemplate(id: "easy_091", title: "Easy Meme 91", resourceName: "easy_091"),
        MemeTemplate(id: "easy_092", title: "Easy Meme 92", resourceName: "easy_092"),
        MemeTemplate(id: "easy_093", title: "Easy Meme 93", resourceName: "easy_093"),
        MemeTemplate(id: "easy_094", title: "Easy Meme 94", resourceName: "easy_094"),
        MemeTemplate(id: "easy_095", title: "Easy Meme 95", resourceName: "easy_095"),
        MemeTemplate(id: "easy_096", title: "Easy Meme 96", resourceName: "easy_096"),
        MemeTemplate(id: "easy_097", title: "Easy Meme 97", resourceName: "easy_097"),
        MemeTemplate(id: "easy_098", title: "Easy Meme 98", resourceName: "easy_098"),
        MemeTemplate(id: "easy_099", title: "Easy Meme 99", resourceName: "easy_099"),
        MemeTemplate(id: "easy_100", title: "Easy Meme 100", resourceName: "easy_100"),
        MemeTemplate(id: "easy_101", title: "Easy Meme 101", resourceName: "easy_101"),
        MemeTemplate(id: "easy_102", title: "Easy Meme 102", resourceName: "easy_102"),
        MemeTemplate(id: "easy_103", title: "Easy Meme 103", resourceName: "easy_103"),
        MemeTemplate(id: "easy_104", title: "Easy Meme 104", resourceName: "easy_104"),
        MemeTemplate(id: "easy_105", title: "Easy Meme 105", resourceName: "easy_105"),
        MemeTemplate(id: "easy_106", title: "Easy Meme 106", resourceName: "easy_106"),
        MemeTemplate(id: "easy_107", title: "Easy Meme 107", resourceName: "easy_107"),
        MemeTemplate(id: "easy_108", title: "Easy Meme 108", resourceName: "easy_108"),
        MemeTemplate(id: "easy_109", title: "Easy Meme 109", resourceName: "easy_109"),
        MemeTemplate(id: "easy_110", title: "Easy Meme 110", resourceName: "easy_110"),
        MemeTemplate(id: "easy_111", title: "Easy Meme 111", resourceName: "easy_111"),
        MemeTemplate(id: "easy_112", title: "Easy Meme 112", resourceName: "easy_112"),
        MemeTemplate(id: "easy_113", title: "Easy Meme 113", resourceName: "easy_113"),
        MemeTemplate(id: "easy_114", title: "Easy Meme 114", resourceName: "easy_114"),
        MemeTemplate(id: "easy_115", title: "Easy Meme 115", resourceName: "easy_115"),
        MemeTemplate(id: "easy_116", title: "Easy Meme 116", resourceName: "easy_116"),
        MemeTemplate(id: "easy_117", title: "Easy Meme 117", resourceName: "easy_117"),
        MemeTemplate(id: "easy_118", title: "Easy Meme 118", resourceName: "easy_118"),
        MemeTemplate(id: "easy_119", title: "Easy Meme 119", resourceName: "easy_119"),
        MemeTemplate(id: "easy_120", title: "Easy Meme 120", resourceName: "easy_120"),
        MemeTemplate(id: "easy_121", title: "Easy Meme 121", resourceName: "easy_121"),
        MemeTemplate(id: "easy_122", title: "Easy Meme 122", resourceName: "easy_122"),
        MemeTemplate(id: "easy_123", title: "Easy Meme 123", resourceName: "easy_123"),
        MemeTemplate(id: "easy_124", title: "Easy Meme 124", resourceName: "easy_124"),
        MemeTemplate(id: "easy_125", title: "Easy Meme 125", resourceName: "easy_125"),
        MemeTemplate(id: "easy_126", title: "Easy Meme 126", resourceName: "easy_126"),
        MemeTemplate(id: "easy_127", title: "Easy Meme 127", resourceName: "easy_127"),
        MemeTemplate(id: "easy_128", title: "Easy Meme 128", resourceName: "easy_128"),
        MemeTemplate(id: "easy_129", title: "Easy Meme 129", resourceName: "easy_129"),
        MemeTemplate(id: "easy_130", title: "Easy Meme 130", resourceName: "easy_130"),
        MemeTemplate(id: "easy_131", title: "Easy Meme 131", resourceName: "easy_131"),
        MemeTemplate(id: "easy_132", title: "Easy Meme 132", resourceName: "easy_132"),
        MemeTemplate(id: "easy_133", title: "Easy Meme 133", resourceName: "easy_133"),
        MemeTemplate(id: "easy_134", title: "Easy Meme 134", resourceName: "easy_134"),
        MemeTemplate(id: "easy_135", title: "Easy Meme 135", resourceName: "easy_135"),
        MemeTemplate(id: "easy_136", title: "Easy Meme 136", resourceName: "easy_136"),
        MemeTemplate(id: "easy_137", title: "Easy Meme 137", resourceName: "easy_137"),
        MemeTemplate(id: "easy_138", title: "Easy Meme 138", resourceName: "easy_138"),
        MemeTemplate(id: "easy_139", title: "Easy Meme 139", resourceName: "easy_139"),
        MemeTemplate(id: "easy_140", title: "Easy Meme 140", resourceName: "easy_140"),
        MemeTemplate(id: "easy_141", title: "Easy Meme 141", resourceName: "easy_141"),
        MemeTemplate(id: "easy_142", title: "Easy Meme 142", resourceName: "easy_142"),
        MemeTemplate(id: "easy_143", title: "Easy Meme 143", resourceName: "easy_143"),
        MemeTemplate(id: "easy_144", title: "Easy Meme 144", resourceName: "easy_144"),
        MemeTemplate(id: "easy_145", title: "Easy Meme 145", resourceName: "easy_145"),
        MemeTemplate(id: "easy_146", title: "Easy Meme 146", resourceName: "easy_146"),
        MemeTemplate(id: "easy_147", title: "Easy Meme 147", resourceName: "easy_147"),
        MemeTemplate(id: "easy_148", title: "Easy Meme 148", resourceName: "easy_148"),
        MemeTemplate(id: "easy_149", title: "Easy Meme 149", resourceName: "easy_149"),
        MemeTemplate(id: "easy_150", title: "Easy Meme 150", resourceName: "easy_150"),
        MemeTemplate(id: "easy_151", title: "Easy Meme 151", resourceName: "easy_151"),
        MemeTemplate(id: "easy_152", title: "Easy Meme 152", resourceName: "easy_152"),
        MemeTemplate(id: "easy_153", title: "Easy Meme 153", resourceName: "easy_153"),
        MemeTemplate(id: "easy_154", title: "Easy Meme 154", resourceName: "easy_154"),
        MemeTemplate(id: "easy_155", title: "Easy Meme 155", resourceName: "easy_155"),
        MemeTemplate(id: "easy_156", title: "Easy Meme 156", resourceName: "easy_156"),
        MemeTemplate(id: "easy_157", title: "Easy Meme 157", resourceName: "easy_157"),
        MemeTemplate(id: "easy_158", title: "Easy Meme 158", resourceName: "easy_158"),
        MemeTemplate(id: "easy_159", title: "Easy Meme 159", resourceName: "easy_159"),
        MemeTemplate(id: "easy_160", title: "Easy Meme 160", resourceName: "easy_160"),
        MemeTemplate(id: "easy_161", title: "Easy Meme 161", resourceName: "easy_161"),
        MemeTemplate(id: "easy_162", title: "Easy Meme 162", resourceName: "easy_162"),
        MemeTemplate(id: "easy_163", title: "Easy Meme 163", resourceName: "easy_163"),
        MemeTemplate(id: "easy_164", title: "Easy Meme 164", resourceName: "easy_164"),
        MemeTemplate(id: "easy_165", title: "Easy Meme 165", resourceName: "easy_165"),
        MemeTemplate(id: "easy_166", title: "Easy Meme 166", resourceName: "easy_166"),
        MemeTemplate(id: "easy_167", title: "Easy Meme 167", resourceName: "easy_167"),
        MemeTemplate(id: "easy_168", title: "Easy Meme 168", resourceName: "easy_168"),
        MemeTemplate(id: "easy_169", title: "Easy Meme 169", resourceName: "easy_169")
    ]

    /// All 169 curated Medium Mode memes (clean AI animal funny memes).
    public static let medium: [MemeTemplate] = [
        MemeTemplate(id: "medium_001", title: "Medium Meme 1", resourceName: "medium_001"),
        MemeTemplate(id: "medium_002", title: "Medium Meme 2", resourceName: "medium_002"),
        MemeTemplate(id: "medium_003", title: "Medium Meme 3", resourceName: "medium_003"),
        MemeTemplate(id: "medium_004", title: "Medium Meme 4", resourceName: "medium_004"),
        MemeTemplate(id: "medium_005", title: "Medium Meme 5", resourceName: "medium_005"),
        MemeTemplate(id: "medium_006", title: "Medium Meme 6", resourceName: "medium_006"),
        MemeTemplate(id: "medium_007", title: "Medium Meme 7", resourceName: "medium_007"),
        MemeTemplate(id: "medium_008", title: "Medium Meme 8", resourceName: "medium_008"),
        MemeTemplate(id: "medium_009", title: "Medium Meme 9", resourceName: "medium_009"),
        MemeTemplate(id: "medium_010", title: "Medium Meme 10", resourceName: "medium_010"),
        MemeTemplate(id: "medium_011", title: "Medium Meme 11", resourceName: "medium_011"),
        MemeTemplate(id: "medium_012", title: "Medium Meme 12", resourceName: "medium_012"),
        MemeTemplate(id: "medium_013", title: "Medium Meme 13", resourceName: "medium_013"),
        MemeTemplate(id: "medium_014", title: "Medium Meme 14", resourceName: "medium_014"),
        MemeTemplate(id: "medium_015", title: "Medium Meme 15", resourceName: "medium_015"),
        MemeTemplate(id: "medium_016", title: "Medium Meme 16", resourceName: "medium_016"),
        MemeTemplate(id: "medium_017", title: "Medium Meme 17", resourceName: "medium_017"),
        MemeTemplate(id: "medium_018", title: "Medium Meme 18", resourceName: "medium_018"),
        MemeTemplate(id: "medium_019", title: "Medium Meme 19", resourceName: "medium_019"),
        MemeTemplate(id: "medium_020", title: "Medium Meme 20", resourceName: "medium_020"),
        MemeTemplate(id: "medium_021", title: "Medium Meme 21", resourceName: "medium_021"),
        MemeTemplate(id: "medium_022", title: "Medium Meme 22", resourceName: "medium_022"),
        MemeTemplate(id: "medium_023", title: "Medium Meme 23", resourceName: "medium_023"),
        MemeTemplate(id: "medium_024", title: "Medium Meme 24", resourceName: "medium_024"),
        MemeTemplate(id: "medium_025", title: "Medium Meme 25", resourceName: "medium_025"),
        MemeTemplate(id: "medium_026", title: "Medium Meme 26", resourceName: "medium_026"),
        MemeTemplate(id: "medium_027", title: "Medium Meme 27", resourceName: "medium_027"),
        MemeTemplate(id: "medium_028", title: "Medium Meme 28", resourceName: "medium_028"),
        MemeTemplate(id: "medium_029", title: "Medium Meme 29", resourceName: "medium_029"),
        MemeTemplate(id: "medium_030", title: "Medium Meme 30", resourceName: "medium_030"),
        MemeTemplate(id: "medium_031", title: "Medium Meme 31", resourceName: "medium_031"),
        MemeTemplate(id: "medium_032", title: "Medium Meme 32", resourceName: "medium_032"),
        MemeTemplate(id: "medium_033", title: "Medium Meme 33", resourceName: "medium_033"),
        MemeTemplate(id: "medium_034", title: "Medium Meme 34", resourceName: "medium_034"),
        MemeTemplate(id: "medium_035", title: "Medium Meme 35", resourceName: "medium_035"),
        MemeTemplate(id: "medium_036", title: "Medium Meme 36", resourceName: "medium_036"),
        MemeTemplate(id: "medium_037", title: "Medium Meme 37", resourceName: "medium_037"),
        MemeTemplate(id: "medium_038", title: "Medium Meme 38", resourceName: "medium_038"),
        MemeTemplate(id: "medium_039", title: "Medium Meme 39", resourceName: "medium_039"),
        MemeTemplate(id: "medium_040", title: "Medium Meme 40", resourceName: "medium_040"),
        MemeTemplate(id: "medium_041", title: "Medium Meme 41", resourceName: "medium_041"),
        MemeTemplate(id: "medium_042", title: "Medium Meme 42", resourceName: "medium_042"),
        MemeTemplate(id: "medium_043", title: "Medium Meme 43", resourceName: "medium_043"),
        MemeTemplate(id: "medium_044", title: "Medium Meme 44", resourceName: "medium_044"),
        MemeTemplate(id: "medium_045", title: "Medium Meme 45", resourceName: "medium_045"),
        MemeTemplate(id: "medium_046", title: "Medium Meme 46", resourceName: "medium_046"),
        MemeTemplate(id: "medium_047", title: "Medium Meme 47", resourceName: "medium_047"),
        MemeTemplate(id: "medium_048", title: "Medium Meme 48", resourceName: "medium_048"),
        MemeTemplate(id: "medium_049", title: "Medium Meme 49", resourceName: "medium_049"),
        MemeTemplate(id: "medium_050", title: "Medium Meme 50", resourceName: "medium_050"),
        MemeTemplate(id: "medium_051", title: "Medium Meme 51", resourceName: "medium_051"),
        MemeTemplate(id: "medium_052", title: "Medium Meme 52", resourceName: "medium_052"),
        MemeTemplate(id: "medium_053", title: "Medium Meme 53", resourceName: "medium_053"),
        MemeTemplate(id: "medium_054", title: "Medium Meme 54", resourceName: "medium_054"),
        MemeTemplate(id: "medium_055", title: "Medium Meme 55", resourceName: "medium_055"),
        MemeTemplate(id: "medium_056", title: "Medium Meme 56", resourceName: "medium_056"),
        MemeTemplate(id: "medium_057", title: "Medium Meme 57", resourceName: "medium_057"),
        MemeTemplate(id: "medium_058", title: "Medium Meme 58", resourceName: "medium_058"),
        MemeTemplate(id: "medium_059", title: "Medium Meme 59", resourceName: "medium_059"),
        MemeTemplate(id: "medium_060", title: "Medium Meme 60", resourceName: "medium_060"),
        MemeTemplate(id: "medium_061", title: "Medium Meme 61", resourceName: "medium_061"),
        MemeTemplate(id: "medium_062", title: "Medium Meme 62", resourceName: "medium_062"),
        MemeTemplate(id: "medium_063", title: "Medium Meme 63", resourceName: "medium_063"),
        MemeTemplate(id: "medium_064", title: "Medium Meme 64", resourceName: "medium_064"),
        MemeTemplate(id: "medium_065", title: "Medium Meme 65", resourceName: "medium_065"),
        MemeTemplate(id: "medium_066", title: "Medium Meme 66", resourceName: "medium_066"),
        MemeTemplate(id: "medium_067", title: "Medium Meme 67", resourceName: "medium_067"),
        MemeTemplate(id: "medium_068", title: "Medium Meme 68", resourceName: "medium_068"),
        MemeTemplate(id: "medium_069", title: "Medium Meme 69", resourceName: "medium_069"),
        MemeTemplate(id: "medium_070", title: "Medium Meme 70", resourceName: "medium_070"),
        MemeTemplate(id: "medium_071", title: "Medium Meme 71", resourceName: "medium_071"),
        MemeTemplate(id: "medium_072", title: "Medium Meme 72", resourceName: "medium_072"),
        MemeTemplate(id: "medium_073", title: "Medium Meme 73", resourceName: "medium_073"),
        MemeTemplate(id: "medium_074", title: "Medium Meme 74", resourceName: "medium_074"),
        MemeTemplate(id: "medium_075", title: "Medium Meme 75", resourceName: "medium_075"),
        MemeTemplate(id: "medium_076", title: "Medium Meme 76", resourceName: "medium_076"),
        MemeTemplate(id: "medium_077", title: "Medium Meme 77", resourceName: "medium_077"),
        MemeTemplate(id: "medium_078", title: "Medium Meme 78", resourceName: "medium_078"),
        MemeTemplate(id: "medium_079", title: "Medium Meme 79", resourceName: "medium_079"),
        MemeTemplate(id: "medium_080", title: "Medium Meme 80", resourceName: "medium_080"),
        MemeTemplate(id: "medium_081", title: "Medium Meme 81", resourceName: "medium_081"),
        MemeTemplate(id: "medium_082", title: "Medium Meme 82", resourceName: "medium_082"),
        MemeTemplate(id: "medium_083", title: "Medium Meme 83", resourceName: "medium_083"),
        MemeTemplate(id: "medium_084", title: "Medium Meme 84", resourceName: "medium_084"),
        MemeTemplate(id: "medium_085", title: "Medium Meme 85", resourceName: "medium_085"),
        MemeTemplate(id: "medium_086", title: "Medium Meme 86", resourceName: "medium_086"),
        MemeTemplate(id: "medium_087", title: "Medium Meme 87", resourceName: "medium_087"),
        MemeTemplate(id: "medium_088", title: "Medium Meme 88", resourceName: "medium_088"),
        MemeTemplate(id: "medium_089", title: "Medium Meme 89", resourceName: "medium_089"),
        MemeTemplate(id: "medium_090", title: "Medium Meme 90", resourceName: "medium_090"),
        MemeTemplate(id: "medium_091", title: "Medium Meme 91", resourceName: "medium_091"),
        MemeTemplate(id: "medium_092", title: "Medium Meme 92", resourceName: "medium_092"),
        MemeTemplate(id: "medium_093", title: "Medium Meme 93", resourceName: "medium_093"),
        MemeTemplate(id: "medium_094", title: "Medium Meme 94", resourceName: "medium_094"),
        MemeTemplate(id: "medium_095", title: "Medium Meme 95", resourceName: "medium_095"),
        MemeTemplate(id: "medium_096", title: "Medium Meme 96", resourceName: "medium_096"),
        MemeTemplate(id: "medium_097", title: "Medium Meme 97", resourceName: "medium_097"),
        MemeTemplate(id: "medium_098", title: "Medium Meme 98", resourceName: "medium_098"),
        MemeTemplate(id: "medium_099", title: "Medium Meme 99", resourceName: "medium_099"),
        MemeTemplate(id: "medium_100", title: "Medium Meme 100", resourceName: "medium_100"),
        MemeTemplate(id: "medium_101", title: "Medium Meme 101", resourceName: "medium_101"),
        MemeTemplate(id: "medium_102", title: "Medium Meme 102", resourceName: "medium_102"),
        MemeTemplate(id: "medium_103", title: "Medium Meme 103", resourceName: "medium_103"),
        MemeTemplate(id: "medium_104", title: "Medium Meme 104", resourceName: "medium_104"),
        MemeTemplate(id: "medium_105", title: "Medium Meme 105", resourceName: "medium_105"),
        MemeTemplate(id: "medium_106", title: "Medium Meme 106", resourceName: "medium_106"),
        MemeTemplate(id: "medium_107", title: "Medium Meme 107", resourceName: "medium_107"),
        MemeTemplate(id: "medium_108", title: "Medium Meme 108", resourceName: "medium_108"),
        MemeTemplate(id: "medium_109", title: "Medium Meme 109", resourceName: "medium_109"),
        MemeTemplate(id: "medium_110", title: "Medium Meme 110", resourceName: "medium_110"),
        MemeTemplate(id: "medium_111", title: "Medium Meme 111", resourceName: "medium_111"),
        MemeTemplate(id: "medium_112", title: "Medium Meme 112", resourceName: "medium_112"),
        MemeTemplate(id: "medium_113", title: "Medium Meme 113", resourceName: "medium_113"),
        MemeTemplate(id: "medium_114", title: "Medium Meme 114", resourceName: "medium_114"),
        MemeTemplate(id: "medium_115", title: "Medium Meme 115", resourceName: "medium_115"),
        MemeTemplate(id: "medium_116", title: "Medium Meme 116", resourceName: "medium_116"),
        MemeTemplate(id: "medium_117", title: "Medium Meme 117", resourceName: "medium_117"),
        MemeTemplate(id: "medium_118", title: "Medium Meme 118", resourceName: "medium_118"),
        MemeTemplate(id: "medium_119", title: "Medium Meme 119", resourceName: "medium_119"),
        MemeTemplate(id: "medium_120", title: "Medium Meme 120", resourceName: "medium_120"),
        MemeTemplate(id: "medium_121", title: "Medium Meme 121", resourceName: "medium_121"),
        MemeTemplate(id: "medium_122", title: "Medium Meme 122", resourceName: "medium_122"),
        MemeTemplate(id: "medium_123", title: "Medium Meme 123", resourceName: "medium_123"),
        MemeTemplate(id: "medium_124", title: "Medium Meme 124", resourceName: "medium_124"),
        MemeTemplate(id: "medium_125", title: "Medium Meme 125", resourceName: "medium_125"),
        MemeTemplate(id: "medium_126", title: "Medium Meme 126", resourceName: "medium_126"),
        MemeTemplate(id: "medium_127", title: "Medium Meme 127", resourceName: "medium_127"),
        MemeTemplate(id: "medium_128", title: "Medium Meme 128", resourceName: "medium_128"),
        MemeTemplate(id: "medium_129", title: "Medium Meme 129", resourceName: "medium_129"),
        MemeTemplate(id: "medium_130", title: "Medium Meme 130", resourceName: "medium_130"),
        MemeTemplate(id: "medium_131", title: "Medium Meme 131", resourceName: "medium_131"),
        MemeTemplate(id: "medium_132", title: "Medium Meme 132", resourceName: "medium_132"),
        MemeTemplate(id: "medium_133", title: "Medium Meme 133", resourceName: "medium_133"),
        MemeTemplate(id: "medium_134", title: "Medium Meme 134", resourceName: "medium_134"),
        MemeTemplate(id: "medium_135", title: "Medium Meme 135", resourceName: "medium_135"),
        MemeTemplate(id: "medium_136", title: "Medium Meme 136", resourceName: "medium_136"),
        MemeTemplate(id: "medium_137", title: "Medium Meme 137", resourceName: "medium_137"),
        MemeTemplate(id: "medium_138", title: "Medium Meme 138", resourceName: "medium_138"),
        MemeTemplate(id: "medium_139", title: "Medium Meme 139", resourceName: "medium_139"),
        MemeTemplate(id: "medium_140", title: "Medium Meme 140", resourceName: "medium_140"),
        MemeTemplate(id: "medium_141", title: "Medium Meme 141", resourceName: "medium_141"),
        MemeTemplate(id: "medium_142", title: "Medium Meme 142", resourceName: "medium_142"),
        MemeTemplate(id: "medium_143", title: "Medium Meme 143", resourceName: "medium_143"),
        MemeTemplate(id: "medium_144", title: "Medium Meme 144", resourceName: "medium_144"),
        MemeTemplate(id: "medium_145", title: "Medium Meme 145", resourceName: "medium_145"),
        MemeTemplate(id: "medium_146", title: "Medium Meme 146", resourceName: "medium_146"),
        MemeTemplate(id: "medium_147", title: "Medium Meme 147", resourceName: "medium_147"),
        MemeTemplate(id: "medium_148", title: "Medium Meme 148", resourceName: "medium_148"),
        MemeTemplate(id: "medium_149", title: "Medium Meme 149", resourceName: "medium_149"),
        MemeTemplate(id: "medium_150", title: "Medium Meme 150", resourceName: "medium_150"),
        MemeTemplate(id: "medium_151", title: "Medium Meme 151", resourceName: "medium_151"),
        MemeTemplate(id: "medium_152", title: "Medium Meme 152", resourceName: "medium_152"),
        MemeTemplate(id: "medium_153", title: "Medium Meme 153", resourceName: "medium_153"),
        MemeTemplate(id: "medium_154", title: "Medium Meme 154", resourceName: "medium_154"),
        MemeTemplate(id: "medium_155", title: "Medium Meme 155", resourceName: "medium_155"),
        MemeTemplate(id: "medium_156", title: "Medium Meme 156", resourceName: "medium_156"),
        MemeTemplate(id: "medium_157", title: "Medium Meme 157", resourceName: "medium_157"),
        MemeTemplate(id: "medium_158", title: "Medium Meme 158", resourceName: "medium_158"),
        MemeTemplate(id: "medium_159", title: "Medium Meme 159", resourceName: "medium_159"),
        MemeTemplate(id: "medium_160", title: "Medium Meme 160", resourceName: "medium_160"),
        MemeTemplate(id: "medium_161", title: "Medium Meme 161", resourceName: "medium_161"),
        MemeTemplate(id: "medium_162", title: "Medium Meme 162", resourceName: "medium_162"),
        MemeTemplate(id: "medium_163", title: "Medium Meme 163", resourceName: "medium_163"),
        MemeTemplate(id: "medium_164", title: "Medium Meme 164", resourceName: "medium_164"),
        MemeTemplate(id: "medium_165", title: "Medium Meme 165", resourceName: "medium_165"),
        MemeTemplate(id: "medium_166", title: "Medium Meme 166", resourceName: "medium_166"),
        MemeTemplate(id: "medium_167", title: "Medium Meme 167", resourceName: "medium_167"),
        MemeTemplate(id: "medium_168", title: "Medium Meme 168", resourceName: "medium_168"),
        MemeTemplate(id: "medium_169", title: "Medium Meme 169", resourceName: "medium_169")
    ]

    /// All 169 curated Hard Mode memes (clean AI animal fantasy memes).
    public static let hard: [MemeTemplate] = [
        MemeTemplate(id: "hard_001", title: "Hard Meme 1", resourceName: "hard_001"),
        MemeTemplate(id: "hard_002", title: "Hard Meme 2", resourceName: "hard_002"),
        MemeTemplate(id: "hard_003", title: "Hard Meme 3", resourceName: "hard_003"),
        MemeTemplate(id: "hard_004", title: "Hard Meme 4", resourceName: "hard_004"),
        MemeTemplate(id: "hard_005", title: "Hard Meme 5", resourceName: "hard_005"),
        MemeTemplate(id: "hard_006", title: "Hard Meme 6", resourceName: "hard_006"),
        MemeTemplate(id: "hard_007", title: "Hard Meme 7", resourceName: "hard_007"),
        MemeTemplate(id: "hard_008", title: "Hard Meme 8", resourceName: "hard_008"),
        MemeTemplate(id: "hard_009", title: "Hard Meme 9", resourceName: "hard_009"),
        MemeTemplate(id: "hard_010", title: "Hard Meme 10", resourceName: "hard_010"),
        MemeTemplate(id: "hard_011", title: "Hard Meme 11", resourceName: "hard_011"),
        MemeTemplate(id: "hard_012", title: "Hard Meme 12", resourceName: "hard_012"),
        MemeTemplate(id: "hard_013", title: "Hard Meme 13", resourceName: "hard_013"),
        MemeTemplate(id: "hard_014", title: "Hard Meme 14", resourceName: "hard_014"),
        MemeTemplate(id: "hard_015", title: "Hard Meme 15", resourceName: "hard_015"),
        MemeTemplate(id: "hard_016", title: "Hard Meme 16", resourceName: "hard_016"),
        MemeTemplate(id: "hard_017", title: "Hard Meme 17", resourceName: "hard_017"),
        MemeTemplate(id: "hard_018", title: "Hard Meme 18", resourceName: "hard_018"),
        MemeTemplate(id: "hard_019", title: "Hard Meme 19", resourceName: "hard_019"),
        MemeTemplate(id: "hard_020", title: "Hard Meme 20", resourceName: "hard_020"),
        MemeTemplate(id: "hard_021", title: "Hard Meme 21", resourceName: "hard_021"),
        MemeTemplate(id: "hard_022", title: "Hard Meme 22", resourceName: "hard_022"),
        MemeTemplate(id: "hard_023", title: "Hard Meme 23", resourceName: "hard_023"),
        MemeTemplate(id: "hard_024", title: "Hard Meme 24", resourceName: "hard_024"),
        MemeTemplate(id: "hard_025", title: "Hard Meme 25", resourceName: "hard_025"),
        MemeTemplate(id: "hard_026", title: "Hard Meme 26", resourceName: "hard_026"),
        MemeTemplate(id: "hard_027", title: "Hard Meme 27", resourceName: "hard_027"),
        MemeTemplate(id: "hard_028", title: "Hard Meme 28", resourceName: "hard_028"),
        MemeTemplate(id: "hard_029", title: "Hard Meme 29", resourceName: "hard_029"),
        MemeTemplate(id: "hard_030", title: "Hard Meme 30", resourceName: "hard_030"),
        MemeTemplate(id: "hard_031", title: "Hard Meme 31", resourceName: "hard_031"),
        MemeTemplate(id: "hard_032", title: "Hard Meme 32", resourceName: "hard_032"),
        MemeTemplate(id: "hard_033", title: "Hard Meme 33", resourceName: "hard_033"),
        MemeTemplate(id: "hard_034", title: "Hard Meme 34", resourceName: "hard_034"),
        MemeTemplate(id: "hard_035", title: "Hard Meme 35", resourceName: "hard_035"),
        MemeTemplate(id: "hard_036", title: "Hard Meme 36", resourceName: "hard_036"),
        MemeTemplate(id: "hard_037", title: "Hard Meme 37", resourceName: "hard_037"),
        MemeTemplate(id: "hard_038", title: "Hard Meme 38", resourceName: "hard_038"),
        MemeTemplate(id: "hard_039", title: "Hard Meme 39", resourceName: "hard_039"),
        MemeTemplate(id: "hard_040", title: "Hard Meme 40", resourceName: "hard_040"),
        MemeTemplate(id: "hard_041", title: "Hard Meme 41", resourceName: "hard_041"),
        MemeTemplate(id: "hard_042", title: "Hard Meme 42", resourceName: "hard_042"),
        MemeTemplate(id: "hard_043", title: "Hard Meme 43", resourceName: "hard_043"),
        MemeTemplate(id: "hard_044", title: "Hard Meme 44", resourceName: "hard_044"),
        MemeTemplate(id: "hard_045", title: "Hard Meme 45", resourceName: "hard_045"),
        MemeTemplate(id: "hard_046", title: "Hard Meme 46", resourceName: "hard_046"),
        MemeTemplate(id: "hard_047", title: "Hard Meme 47", resourceName: "hard_047"),
        MemeTemplate(id: "hard_048", title: "Hard Meme 48", resourceName: "hard_048"),
        MemeTemplate(id: "hard_049", title: "Hard Meme 49", resourceName: "hard_049"),
        MemeTemplate(id: "hard_050", title: "Hard Meme 50", resourceName: "hard_050"),
        MemeTemplate(id: "hard_051", title: "Hard Meme 51", resourceName: "hard_051"),
        MemeTemplate(id: "hard_052", title: "Hard Meme 52", resourceName: "hard_052"),
        MemeTemplate(id: "hard_053", title: "Hard Meme 53", resourceName: "hard_053"),
        MemeTemplate(id: "hard_054", title: "Hard Meme 54", resourceName: "hard_054"),
        MemeTemplate(id: "hard_055", title: "Hard Meme 55", resourceName: "hard_055"),
        MemeTemplate(id: "hard_056", title: "Hard Meme 56", resourceName: "hard_056"),
        MemeTemplate(id: "hard_057", title: "Hard Meme 57", resourceName: "hard_057"),
        MemeTemplate(id: "hard_058", title: "Hard Meme 58", resourceName: "hard_058"),
        MemeTemplate(id: "hard_059", title: "Hard Meme 59", resourceName: "hard_059"),
        MemeTemplate(id: "hard_060", title: "Hard Meme 60", resourceName: "hard_060"),
        MemeTemplate(id: "hard_061", title: "Hard Meme 61", resourceName: "hard_061"),
        MemeTemplate(id: "hard_062", title: "Hard Meme 62", resourceName: "hard_062"),
        MemeTemplate(id: "hard_063", title: "Hard Meme 63", resourceName: "hard_063"),
        MemeTemplate(id: "hard_064", title: "Hard Meme 64", resourceName: "hard_064"),
        MemeTemplate(id: "hard_065", title: "Hard Meme 65", resourceName: "hard_065"),
        MemeTemplate(id: "hard_066", title: "Hard Meme 66", resourceName: "hard_066"),
        MemeTemplate(id: "hard_067", title: "Hard Meme 67", resourceName: "hard_067"),
        MemeTemplate(id: "hard_068", title: "Hard Meme 68", resourceName: "hard_068"),
        MemeTemplate(id: "hard_069", title: "Hard Meme 69", resourceName: "hard_069"),
        MemeTemplate(id: "hard_070", title: "Hard Meme 70", resourceName: "hard_070"),
        MemeTemplate(id: "hard_071", title: "Hard Meme 71", resourceName: "hard_071"),
        MemeTemplate(id: "hard_072", title: "Hard Meme 72", resourceName: "hard_072"),
        MemeTemplate(id: "hard_073", title: "Hard Meme 73", resourceName: "hard_073"),
        MemeTemplate(id: "hard_074", title: "Hard Meme 74", resourceName: "hard_074"),
        MemeTemplate(id: "hard_075", title: "Hard Meme 75", resourceName: "hard_075"),
        MemeTemplate(id: "hard_076", title: "Hard Meme 76", resourceName: "hard_076"),
        MemeTemplate(id: "hard_077", title: "Hard Meme 77", resourceName: "hard_077"),
        MemeTemplate(id: "hard_078", title: "Hard Meme 78", resourceName: "hard_078"),
        MemeTemplate(id: "hard_079", title: "Hard Meme 79", resourceName: "hard_079"),
        MemeTemplate(id: "hard_080", title: "Hard Meme 80", resourceName: "hard_080"),
        MemeTemplate(id: "hard_081", title: "Hard Meme 81", resourceName: "hard_081"),
        MemeTemplate(id: "hard_082", title: "Hard Meme 82", resourceName: "hard_082"),
        MemeTemplate(id: "hard_083", title: "Hard Meme 83", resourceName: "hard_083"),
        MemeTemplate(id: "hard_084", title: "Hard Meme 84", resourceName: "hard_084"),
        MemeTemplate(id: "hard_085", title: "Hard Meme 85", resourceName: "hard_085"),
        MemeTemplate(id: "hard_086", title: "Hard Meme 86", resourceName: "hard_086"),
        MemeTemplate(id: "hard_087", title: "Hard Meme 87", resourceName: "hard_087"),
        MemeTemplate(id: "hard_088", title: "Hard Meme 88", resourceName: "hard_088"),
        MemeTemplate(id: "hard_089", title: "Hard Meme 89", resourceName: "hard_089"),
        MemeTemplate(id: "hard_090", title: "Hard Meme 90", resourceName: "hard_090"),
        MemeTemplate(id: "hard_091", title: "Hard Meme 91", resourceName: "hard_091"),
        MemeTemplate(id: "hard_092", title: "Hard Meme 92", resourceName: "hard_092"),
        MemeTemplate(id: "hard_093", title: "Hard Meme 93", resourceName: "hard_093"),
        MemeTemplate(id: "hard_094", title: "Hard Meme 94", resourceName: "hard_094"),
        MemeTemplate(id: "hard_095", title: "Hard Meme 95", resourceName: "hard_095"),
        MemeTemplate(id: "hard_096", title: "Hard Meme 96", resourceName: "hard_096"),
        MemeTemplate(id: "hard_097", title: "Hard Meme 97", resourceName: "hard_097"),
        MemeTemplate(id: "hard_098", title: "Hard Meme 98", resourceName: "hard_098"),
        MemeTemplate(id: "hard_099", title: "Hard Meme 99", resourceName: "hard_099"),
        MemeTemplate(id: "hard_100", title: "Hard Meme 100", resourceName: "hard_100"),
        MemeTemplate(id: "hard_101", title: "Hard Meme 101", resourceName: "hard_101"),
        MemeTemplate(id: "hard_102", title: "Hard Meme 102", resourceName: "hard_102"),
        MemeTemplate(id: "hard_103", title: "Hard Meme 103", resourceName: "hard_103"),
        MemeTemplate(id: "hard_104", title: "Hard Meme 104", resourceName: "hard_104"),
        MemeTemplate(id: "hard_105", title: "Hard Meme 105", resourceName: "hard_105"),
        MemeTemplate(id: "hard_106", title: "Hard Meme 106", resourceName: "hard_106"),
        MemeTemplate(id: "hard_107", title: "Hard Meme 107", resourceName: "hard_107"),
        MemeTemplate(id: "hard_108", title: "Hard Meme 108", resourceName: "hard_108"),
        MemeTemplate(id: "hard_109", title: "Hard Meme 109", resourceName: "hard_109"),
        MemeTemplate(id: "hard_110", title: "Hard Meme 110", resourceName: "hard_110"),
        MemeTemplate(id: "hard_111", title: "Hard Meme 111", resourceName: "hard_111"),
        MemeTemplate(id: "hard_112", title: "Hard Meme 112", resourceName: "hard_112"),
        MemeTemplate(id: "hard_113", title: "Hard Meme 113", resourceName: "hard_113"),
        MemeTemplate(id: "hard_114", title: "Hard Meme 114", resourceName: "hard_114"),
        MemeTemplate(id: "hard_115", title: "Hard Meme 115", resourceName: "hard_115"),
        MemeTemplate(id: "hard_116", title: "Hard Meme 116", resourceName: "hard_116"),
        MemeTemplate(id: "hard_117", title: "Hard Meme 117", resourceName: "hard_117"),
        MemeTemplate(id: "hard_118", title: "Hard Meme 118", resourceName: "hard_118"),
        MemeTemplate(id: "hard_119", title: "Hard Meme 119", resourceName: "hard_119"),
        MemeTemplate(id: "hard_120", title: "Hard Meme 120", resourceName: "hard_120"),
        MemeTemplate(id: "hard_121", title: "Hard Meme 121", resourceName: "hard_121"),
        MemeTemplate(id: "hard_122", title: "Hard Meme 122", resourceName: "hard_122"),
        MemeTemplate(id: "hard_123", title: "Hard Meme 123", resourceName: "hard_123"),
        MemeTemplate(id: "hard_124", title: "Hard Meme 124", resourceName: "hard_124"),
        MemeTemplate(id: "hard_125", title: "Hard Meme 125", resourceName: "hard_125"),
        MemeTemplate(id: "hard_126", title: "Hard Meme 126", resourceName: "hard_126"),
        MemeTemplate(id: "hard_127", title: "Hard Meme 127", resourceName: "hard_127"),
        MemeTemplate(id: "hard_128", title: "Hard Meme 128", resourceName: "hard_128"),
        MemeTemplate(id: "hard_129", title: "Hard Meme 129", resourceName: "hard_129"),
        MemeTemplate(id: "hard_130", title: "Hard Meme 130", resourceName: "hard_130"),
        MemeTemplate(id: "hard_131", title: "Hard Meme 131", resourceName: "hard_131"),
        MemeTemplate(id: "hard_132", title: "Hard Meme 132", resourceName: "hard_132"),
        MemeTemplate(id: "hard_133", title: "Hard Meme 133", resourceName: "hard_133"),
        MemeTemplate(id: "hard_134", title: "Hard Meme 134", resourceName: "hard_134"),
        MemeTemplate(id: "hard_135", title: "Hard Meme 135", resourceName: "hard_135"),
        MemeTemplate(id: "hard_136", title: "Hard Meme 136", resourceName: "hard_136"),
        MemeTemplate(id: "hard_137", title: "Hard Meme 137", resourceName: "hard_137"),
        MemeTemplate(id: "hard_138", title: "Hard Meme 138", resourceName: "hard_138"),
        MemeTemplate(id: "hard_139", title: "Hard Meme 139", resourceName: "hard_139"),
        MemeTemplate(id: "hard_140", title: "Hard Meme 140", resourceName: "hard_140"),
        MemeTemplate(id: "hard_141", title: "Hard Meme 141", resourceName: "hard_141"),
        MemeTemplate(id: "hard_142", title: "Hard Meme 142", resourceName: "hard_142"),
        MemeTemplate(id: "hard_143", title: "Hard Meme 143", resourceName: "hard_143"),
        MemeTemplate(id: "hard_144", title: "Hard Meme 144", resourceName: "hard_144"),
        MemeTemplate(id: "hard_145", title: "Hard Meme 145", resourceName: "hard_145"),
        MemeTemplate(id: "hard_146", title: "Hard Meme 146", resourceName: "hard_146"),
        MemeTemplate(id: "hard_147", title: "Hard Meme 147", resourceName: "hard_147"),
        MemeTemplate(id: "hard_148", title: "Hard Meme 148", resourceName: "hard_148"),
        MemeTemplate(id: "hard_149", title: "Hard Meme 149", resourceName: "hard_149"),
        MemeTemplate(id: "hard_150", title: "Hard Meme 150", resourceName: "hard_150"),
        MemeTemplate(id: "hard_151", title: "Hard Meme 151", resourceName: "hard_151"),
        MemeTemplate(id: "hard_152", title: "Hard Meme 152", resourceName: "hard_152"),
        MemeTemplate(id: "hard_153", title: "Hard Meme 153", resourceName: "hard_153"),
        MemeTemplate(id: "hard_154", title: "Hard Meme 154", resourceName: "hard_154"),
        MemeTemplate(id: "hard_155", title: "Hard Meme 155", resourceName: "hard_155"),
        MemeTemplate(id: "hard_156", title: "Hard Meme 156", resourceName: "hard_156"),
        MemeTemplate(id: "hard_157", title: "Hard Meme 157", resourceName: "hard_157"),
        MemeTemplate(id: "hard_158", title: "Hard Meme 158", resourceName: "hard_158"),
        MemeTemplate(id: "hard_159", title: "Hard Meme 159", resourceName: "hard_159"),
        MemeTemplate(id: "hard_160", title: "Hard Meme 160", resourceName: "hard_160"),
        MemeTemplate(id: "hard_161", title: "Hard Meme 161", resourceName: "hard_161"),
        MemeTemplate(id: "hard_162", title: "Hard Meme 162", resourceName: "hard_162"),
        MemeTemplate(id: "hard_163", title: "Hard Meme 163", resourceName: "hard_163"),
        MemeTemplate(id: "hard_164", title: "Hard Meme 164", resourceName: "hard_164"),
        MemeTemplate(id: "hard_165", title: "Hard Meme 165", resourceName: "hard_165"),
        MemeTemplate(id: "hard_166", title: "Hard Meme 166", resourceName: "hard_166"),
        MemeTemplate(id: "hard_167", title: "Hard Meme 167", resourceName: "hard_167"),
        MemeTemplate(id: "hard_168", title: "Hard Meme 168", resourceName: "hard_168"),
        MemeTemplate(id: "hard_169", title: "Hard Meme 169", resourceName: "hard_169")
    ]

    /// All 169 curated Extreme Mode memes (clean AI animal fantasy memes).
    public static let extreme: [MemeTemplate] = [
        MemeTemplate(id: "extreme_001", title: "Extreme Meme 1", resourceName: "extreme_001"),
        MemeTemplate(id: "extreme_002", title: "Extreme Meme 2", resourceName: "extreme_002"),
        MemeTemplate(id: "extreme_003", title: "Extreme Meme 3", resourceName: "extreme_003"),
        MemeTemplate(id: "extreme_004", title: "Extreme Meme 4", resourceName: "extreme_004"),
        MemeTemplate(id: "extreme_005", title: "Extreme Meme 5", resourceName: "extreme_005"),
        MemeTemplate(id: "extreme_006", title: "Extreme Meme 6", resourceName: "extreme_006"),
        MemeTemplate(id: "extreme_007", title: "Extreme Meme 7", resourceName: "extreme_007"),
        MemeTemplate(id: "extreme_008", title: "Extreme Meme 8", resourceName: "extreme_008"),
        MemeTemplate(id: "extreme_009", title: "Extreme Meme 9", resourceName: "extreme_009"),
        MemeTemplate(id: "extreme_010", title: "Extreme Meme 10", resourceName: "extreme_010"),
        MemeTemplate(id: "extreme_011", title: "Extreme Meme 11", resourceName: "extreme_011"),
        MemeTemplate(id: "extreme_012", title: "Extreme Meme 12", resourceName: "extreme_012"),
        MemeTemplate(id: "extreme_013", title: "Extreme Meme 13", resourceName: "extreme_013"),
        MemeTemplate(id: "extreme_014", title: "Extreme Meme 14", resourceName: "extreme_014"),
        MemeTemplate(id: "extreme_015", title: "Extreme Meme 15", resourceName: "extreme_015"),
        MemeTemplate(id: "extreme_016", title: "Extreme Meme 16", resourceName: "extreme_016"),
        MemeTemplate(id: "extreme_017", title: "Extreme Meme 17", resourceName: "extreme_017"),
        MemeTemplate(id: "extreme_018", title: "Extreme Meme 18", resourceName: "extreme_018"),
        MemeTemplate(id: "extreme_019", title: "Extreme Meme 19", resourceName: "extreme_019"),
        MemeTemplate(id: "extreme_020", title: "Extreme Meme 20", resourceName: "extreme_020"),
        MemeTemplate(id: "extreme_021", title: "Extreme Meme 21", resourceName: "extreme_021"),
        MemeTemplate(id: "extreme_022", title: "Extreme Meme 22", resourceName: "extreme_022"),
        MemeTemplate(id: "extreme_023", title: "Extreme Meme 23", resourceName: "extreme_023"),
        MemeTemplate(id: "extreme_024", title: "Extreme Meme 24", resourceName: "extreme_024"),
        MemeTemplate(id: "extreme_025", title: "Extreme Meme 25", resourceName: "extreme_025"),
        MemeTemplate(id: "extreme_026", title: "Extreme Meme 26", resourceName: "extreme_026"),
        MemeTemplate(id: "extreme_027", title: "Extreme Meme 27", resourceName: "extreme_027"),
        MemeTemplate(id: "extreme_028", title: "Extreme Meme 28", resourceName: "extreme_028"),
        MemeTemplate(id: "extreme_029", title: "Extreme Meme 29", resourceName: "extreme_029"),
        MemeTemplate(id: "extreme_030", title: "Extreme Meme 30", resourceName: "extreme_030"),
        MemeTemplate(id: "extreme_031", title: "Extreme Meme 31", resourceName: "extreme_031"),
        MemeTemplate(id: "extreme_032", title: "Extreme Meme 32", resourceName: "extreme_032"),
        MemeTemplate(id: "extreme_033", title: "Extreme Meme 33", resourceName: "extreme_033"),
        MemeTemplate(id: "extreme_034", title: "Extreme Meme 34", resourceName: "extreme_034"),
        MemeTemplate(id: "extreme_035", title: "Extreme Meme 35", resourceName: "extreme_035"),
        MemeTemplate(id: "extreme_036", title: "Extreme Meme 36", resourceName: "extreme_036"),
        MemeTemplate(id: "extreme_037", title: "Extreme Meme 37", resourceName: "extreme_037"),
        MemeTemplate(id: "extreme_038", title: "Extreme Meme 38", resourceName: "extreme_038"),
        MemeTemplate(id: "extreme_039", title: "Extreme Meme 39", resourceName: "extreme_039"),
        MemeTemplate(id: "extreme_040", title: "Extreme Meme 40", resourceName: "extreme_040"),
        MemeTemplate(id: "extreme_041", title: "Extreme Meme 41", resourceName: "extreme_041"),
        MemeTemplate(id: "extreme_042", title: "Extreme Meme 42", resourceName: "extreme_042"),
        MemeTemplate(id: "extreme_043", title: "Extreme Meme 43", resourceName: "extreme_043"),
        MemeTemplate(id: "extreme_044", title: "Extreme Meme 44", resourceName: "extreme_044"),
        MemeTemplate(id: "extreme_045", title: "Extreme Meme 45", resourceName: "extreme_045"),
        MemeTemplate(id: "extreme_046", title: "Extreme Meme 46", resourceName: "extreme_046"),
        MemeTemplate(id: "extreme_047", title: "Extreme Meme 47", resourceName: "extreme_047"),
        MemeTemplate(id: "extreme_048", title: "Extreme Meme 48", resourceName: "extreme_048"),
        MemeTemplate(id: "extreme_049", title: "Extreme Meme 49", resourceName: "extreme_049"),
        MemeTemplate(id: "extreme_050", title: "Extreme Meme 50", resourceName: "extreme_050"),
        MemeTemplate(id: "extreme_051", title: "Extreme Meme 51", resourceName: "extreme_051"),
        MemeTemplate(id: "extreme_052", title: "Extreme Meme 52", resourceName: "extreme_052"),
        MemeTemplate(id: "extreme_053", title: "Extreme Meme 53", resourceName: "extreme_053"),
        MemeTemplate(id: "extreme_054", title: "Extreme Meme 54", resourceName: "extreme_054"),
        MemeTemplate(id: "extreme_055", title: "Extreme Meme 55", resourceName: "extreme_055"),
        MemeTemplate(id: "extreme_056", title: "Extreme Meme 56", resourceName: "extreme_056"),
        MemeTemplate(id: "extreme_057", title: "Extreme Meme 57", resourceName: "extreme_057"),
        MemeTemplate(id: "extreme_058", title: "Extreme Meme 58", resourceName: "extreme_058"),
        MemeTemplate(id: "extreme_059", title: "Extreme Meme 59", resourceName: "extreme_059"),
        MemeTemplate(id: "extreme_060", title: "Extreme Meme 60", resourceName: "extreme_060"),
        MemeTemplate(id: "extreme_061", title: "Extreme Meme 61", resourceName: "extreme_061"),
        MemeTemplate(id: "extreme_062", title: "Extreme Meme 62", resourceName: "extreme_062"),
        MemeTemplate(id: "extreme_063", title: "Extreme Meme 63", resourceName: "extreme_063"),
        MemeTemplate(id: "extreme_064", title: "Extreme Meme 64", resourceName: "extreme_064"),
        MemeTemplate(id: "extreme_065", title: "Extreme Meme 65", resourceName: "extreme_065"),
        MemeTemplate(id: "extreme_066", title: "Extreme Meme 66", resourceName: "extreme_066"),
        MemeTemplate(id: "extreme_067", title: "Extreme Meme 67", resourceName: "extreme_067"),
        MemeTemplate(id: "extreme_068", title: "Extreme Meme 68", resourceName: "extreme_068"),
        MemeTemplate(id: "extreme_069", title: "Extreme Meme 69", resourceName: "extreme_069"),
        MemeTemplate(id: "extreme_070", title: "Extreme Meme 70", resourceName: "extreme_070"),
        MemeTemplate(id: "extreme_071", title: "Extreme Meme 71", resourceName: "extreme_071"),
        MemeTemplate(id: "extreme_072", title: "Extreme Meme 72", resourceName: "extreme_072"),
        MemeTemplate(id: "extreme_073", title: "Extreme Meme 73", resourceName: "extreme_073"),
        MemeTemplate(id: "extreme_074", title: "Extreme Meme 74", resourceName: "extreme_074"),
        MemeTemplate(id: "extreme_075", title: "Extreme Meme 75", resourceName: "extreme_075"),
        MemeTemplate(id: "extreme_076", title: "Extreme Meme 76", resourceName: "extreme_076"),
        MemeTemplate(id: "extreme_077", title: "Extreme Meme 77", resourceName: "extreme_077"),
        MemeTemplate(id: "extreme_078", title: "Extreme Meme 78", resourceName: "extreme_078"),
        MemeTemplate(id: "extreme_079", title: "Extreme Meme 79", resourceName: "extreme_079"),
        MemeTemplate(id: "extreme_080", title: "Extreme Meme 80", resourceName: "extreme_080"),
        MemeTemplate(id: "extreme_081", title: "Extreme Meme 81", resourceName: "extreme_081"),
        MemeTemplate(id: "extreme_082", title: "Extreme Meme 82", resourceName: "extreme_082"),
        MemeTemplate(id: "extreme_083", title: "Extreme Meme 83", resourceName: "extreme_083"),
        MemeTemplate(id: "extreme_084", title: "Extreme Meme 84", resourceName: "extreme_084"),
        MemeTemplate(id: "extreme_085", title: "Extreme Meme 85", resourceName: "extreme_085"),
        MemeTemplate(id: "extreme_086", title: "Extreme Meme 86", resourceName: "extreme_086"),
        MemeTemplate(id: "extreme_087", title: "Extreme Meme 87", resourceName: "extreme_087"),
        MemeTemplate(id: "extreme_088", title: "Extreme Meme 88", resourceName: "extreme_088"),
        MemeTemplate(id: "extreme_089", title: "Extreme Meme 89", resourceName: "extreme_089"),
        MemeTemplate(id: "extreme_090", title: "Extreme Meme 90", resourceName: "extreme_090"),
        MemeTemplate(id: "extreme_091", title: "Extreme Meme 91", resourceName: "extreme_091"),
        MemeTemplate(id: "extreme_092", title: "Extreme Meme 92", resourceName: "extreme_092"),
        MemeTemplate(id: "extreme_093", title: "Extreme Meme 93", resourceName: "extreme_093"),
        MemeTemplate(id: "extreme_094", title: "Extreme Meme 94", resourceName: "extreme_094"),
        MemeTemplate(id: "extreme_095", title: "Extreme Meme 95", resourceName: "extreme_095"),
        MemeTemplate(id: "extreme_096", title: "Extreme Meme 96", resourceName: "extreme_096"),
        MemeTemplate(id: "extreme_097", title: "Extreme Meme 97", resourceName: "extreme_097"),
        MemeTemplate(id: "extreme_098", title: "Extreme Meme 98", resourceName: "extreme_098"),
        MemeTemplate(id: "extreme_099", title: "Extreme Meme 99", resourceName: "extreme_099"),
        MemeTemplate(id: "extreme_100", title: "Extreme Meme 100", resourceName: "extreme_100"),
        MemeTemplate(id: "extreme_101", title: "Extreme Meme 101", resourceName: "extreme_101"),
        MemeTemplate(id: "extreme_102", title: "Extreme Meme 102", resourceName: "extreme_102"),
        MemeTemplate(id: "extreme_103", title: "Extreme Meme 103", resourceName: "extreme_103"),
        MemeTemplate(id: "extreme_104", title: "Extreme Meme 104", resourceName: "extreme_104"),
        MemeTemplate(id: "extreme_105", title: "Extreme Meme 105", resourceName: "extreme_105"),
        MemeTemplate(id: "extreme_106", title: "Extreme Meme 106", resourceName: "extreme_106"),
        MemeTemplate(id: "extreme_107", title: "Extreme Meme 107", resourceName: "extreme_107"),
        MemeTemplate(id: "extreme_108", title: "Extreme Meme 108", resourceName: "extreme_108"),
        MemeTemplate(id: "extreme_109", title: "Extreme Meme 109", resourceName: "extreme_109"),
        MemeTemplate(id: "extreme_110", title: "Extreme Meme 110", resourceName: "extreme_110"),
        MemeTemplate(id: "extreme_111", title: "Extreme Meme 111", resourceName: "extreme_111"),
        MemeTemplate(id: "extreme_112", title: "Extreme Meme 112", resourceName: "extreme_112"),
        MemeTemplate(id: "extreme_113", title: "Extreme Meme 113", resourceName: "extreme_113"),
        MemeTemplate(id: "extreme_114", title: "Extreme Meme 114", resourceName: "extreme_114"),
        MemeTemplate(id: "extreme_115", title: "Extreme Meme 115", resourceName: "extreme_115"),
        MemeTemplate(id: "extreme_116", title: "Extreme Meme 116", resourceName: "extreme_116"),
        MemeTemplate(id: "extreme_117", title: "Extreme Meme 117", resourceName: "extreme_117"),
        MemeTemplate(id: "extreme_118", title: "Extreme Meme 118", resourceName: "extreme_118"),
        MemeTemplate(id: "extreme_119", title: "Extreme Meme 119", resourceName: "extreme_119"),
        MemeTemplate(id: "extreme_120", title: "Extreme Meme 120", resourceName: "extreme_120"),
        MemeTemplate(id: "extreme_121", title: "Extreme Meme 121", resourceName: "extreme_121"),
        MemeTemplate(id: "extreme_122", title: "Extreme Meme 122", resourceName: "extreme_122"),
        MemeTemplate(id: "extreme_123", title: "Extreme Meme 123", resourceName: "extreme_123"),
        MemeTemplate(id: "extreme_124", title: "Extreme Meme 124", resourceName: "extreme_124"),
        MemeTemplate(id: "extreme_125", title: "Extreme Meme 125", resourceName: "extreme_125"),
        MemeTemplate(id: "extreme_126", title: "Extreme Meme 126", resourceName: "extreme_126"),
        MemeTemplate(id: "extreme_127", title: "Extreme Meme 127", resourceName: "extreme_127"),
        MemeTemplate(id: "extreme_128", title: "Extreme Meme 128", resourceName: "extreme_128"),
        MemeTemplate(id: "extreme_129", title: "Extreme Meme 129", resourceName: "extreme_129"),
        MemeTemplate(id: "extreme_130", title: "Extreme Meme 130", resourceName: "extreme_130"),
        MemeTemplate(id: "extreme_131", title: "Extreme Meme 131", resourceName: "extreme_131"),
        MemeTemplate(id: "extreme_132", title: "Extreme Meme 132", resourceName: "extreme_132"),
        MemeTemplate(id: "extreme_133", title: "Extreme Meme 133", resourceName: "extreme_133"),
        MemeTemplate(id: "extreme_134", title: "Extreme Meme 134", resourceName: "extreme_134"),
        MemeTemplate(id: "extreme_135", title: "Extreme Meme 135", resourceName: "extreme_135"),
        MemeTemplate(id: "extreme_136", title: "Extreme Meme 136", resourceName: "extreme_136"),
        MemeTemplate(id: "extreme_137", title: "Extreme Meme 137", resourceName: "extreme_137"),
        MemeTemplate(id: "extreme_138", title: "Extreme Meme 138", resourceName: "extreme_138"),
        MemeTemplate(id: "extreme_139", title: "Extreme Meme 139", resourceName: "extreme_139"),
        MemeTemplate(id: "extreme_140", title: "Extreme Meme 140", resourceName: "extreme_140"),
        MemeTemplate(id: "extreme_141", title: "Extreme Meme 141", resourceName: "extreme_141"),
        MemeTemplate(id: "extreme_142", title: "Extreme Meme 142", resourceName: "extreme_142"),
        MemeTemplate(id: "extreme_143", title: "Extreme Meme 143", resourceName: "extreme_143"),
        MemeTemplate(id: "extreme_144", title: "Extreme Meme 144", resourceName: "extreme_144"),
        MemeTemplate(id: "extreme_145", title: "Extreme Meme 145", resourceName: "extreme_145"),
        MemeTemplate(id: "extreme_146", title: "Extreme Meme 146", resourceName: "extreme_146"),
        MemeTemplate(id: "extreme_147", title: "Extreme Meme 147", resourceName: "extreme_147"),
        MemeTemplate(id: "extreme_148", title: "Extreme Meme 148", resourceName: "extreme_148"),
        MemeTemplate(id: "extreme_149", title: "Extreme Meme 149", resourceName: "extreme_149"),
        MemeTemplate(id: "extreme_150", title: "Extreme Meme 150", resourceName: "extreme_150"),
        MemeTemplate(id: "extreme_151", title: "Extreme Meme 151", resourceName: "extreme_151"),
        MemeTemplate(id: "extreme_152", title: "Extreme Meme 152", resourceName: "extreme_152"),
        MemeTemplate(id: "extreme_153", title: "Extreme Meme 153", resourceName: "extreme_153"),
        MemeTemplate(id: "extreme_154", title: "Extreme Meme 154", resourceName: "extreme_154"),
        MemeTemplate(id: "extreme_155", title: "Extreme Meme 155", resourceName: "extreme_155"),
        MemeTemplate(id: "extreme_156", title: "Extreme Meme 156", resourceName: "extreme_156"),
        MemeTemplate(id: "extreme_157", title: "Extreme Meme 157", resourceName: "extreme_157"),
        MemeTemplate(id: "extreme_158", title: "Extreme Meme 158", resourceName: "extreme_158"),
        MemeTemplate(id: "extreme_159", title: "Extreme Meme 159", resourceName: "extreme_159"),
        MemeTemplate(id: "extreme_160", title: "Extreme Meme 160", resourceName: "extreme_160"),
        MemeTemplate(id: "extreme_161", title: "Extreme Meme 161", resourceName: "extreme_161"),
        MemeTemplate(id: "extreme_162", title: "Extreme Meme 162", resourceName: "extreme_162"),
        MemeTemplate(id: "extreme_163", title: "Extreme Meme 163", resourceName: "extreme_163"),
        MemeTemplate(id: "extreme_164", title: "Extreme Meme 164", resourceName: "extreme_164"),
        MemeTemplate(id: "extreme_165", title: "Extreme Meme 165", resourceName: "extreme_165"),
        MemeTemplate(id: "extreme_166", title: "Extreme Meme 166", resourceName: "extreme_166"),
        MemeTemplate(id: "extreme_167", title: "Extreme Meme 167", resourceName: "extreme_167"),
        MemeTemplate(id: "extreme_168", title: "Extreme Meme 168", resourceName: "extreme_168"),
        MemeTemplate(id: "extreme_169", title: "Extreme Meme 169", resourceName: "extreme_169")
    ]

    /// Returns the active meme pool for the chosen difficulty mode.
    public static func templates(for mode: DifficultyMode) -> [MemeTemplate] {
        switch mode {
        case .easy:
            return easy
        case .medium:
            return medium.isEmpty ? easy : medium
        case .hard:
            return hard.isEmpty ? (medium.isEmpty ? easy : medium) : hard
        case .extreme:
            return extreme.isEmpty ? (hard.isEmpty ? (medium.isEmpty ? easy : medium) : hard) : extreme
        }
    }

    /// Alias for templates(for:) used in collection views.
    public static func memes(for mode: DifficultyMode) -> [MemeTemplate] {
        templates(for: mode)
    }

    /// All bundled memes across all difficulty tiers.
    public static var bundled: [MemeTemplate] {
        easy + medium + hard + extreme
    }

    /// Daily Blitz templates (100 Days of Horror Fantasy AI artwork).
    public static let daily: [MemeTemplate] = (1...100).map { i in
        let padded = String(format: "%03d", i)
        return MemeTemplate(
            id: "daily_\(padded)",
            title: "Daily Blitz #\(padded)",
            resourceName: "daily_\(padded)",
            topText: "DAILY BLITZ",
            bottomText: "DAY \(i)"
        )
    }

    /// Fetches the Daily Blitz template for a specific day number (1...100).
    public static func dailyTemplate(for dayNumber: Int) -> MemeTemplate {
        let index = ((dayNumber - 1) % 100 + 100) % 100
        return daily[index]
    }
}

/// A meme imported from the user's photo library.
public struct ImportedMeme: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let image: UIImage
    public var topText: String
    public var bottomText: String

    public init(id: UUID = UUID(), image: UIImage, topText: String = "", bottomText: String = "") {
        self.id = id
        self.image = image
        self.topText = topText
        self.bottomText = bottomText
    }
}

/// A remotely served meme discovered from the local server or drop directory feed.
public struct RemoteMeme: Identifiable, Hashable, Sendable, Codable {
    public let id: String
    public let title: String
    public let filename: String
    public let src: String
    public let topText: String
    public let bottomText: String
    public let isRemote: Bool

    public init(id: String, title: String, filename: String, src: String, topText: String = "", bottomText: String = "", isRemote: Bool = true) {
        self.id = id
        self.title = title
        self.filename = filename
        self.src = src
        self.topText = topText
        self.bottomText = bottomText
        self.isRemote = isRemote
    }
}

/// Where a puzzle image comes from.
public enum MemeSource: Hashable, Sendable {
    case bundled(MemeTemplate)
    case imported(ImportedMeme)
    case remote(RemoteMeme)

    public var id: String {
        switch self {
        case .bundled(let template): template.id
        case .imported(let imported): imported.id.uuidString
        case .remote(let remote): remote.id
        }
    }

    public var title: String {
        switch self {
        case .bundled(let template): template.title
        case .imported: "Your Meme"
        case .remote(let remote): remote.title
        }
    }
}


/// A fully configured puzzle game launch session.
public struct PuzzleSession: Identifiable, Hashable, Sendable {
    public let id: String
    public let source: MemeSource
    public let configuration: PuzzleConfiguration
    public let seed: UInt64?

    public init(source: MemeSource, configuration: PuzzleConfiguration, seed: UInt64? = nil) {
        self.id = "\(source.id).\(seed ?? 0)"
        self.source = source
        self.configuration = configuration
        self.seed = seed
    }
}
