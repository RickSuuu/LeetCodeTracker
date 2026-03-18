import Cocoa
import SwiftUI

// MARK: - Data Model

struct Problem: Codable, Identifiable {
    let id: Int
    let name: String
    let difficulty: String
    let slug: String
    var done: Bool = false
}

struct Category: Codable, Identifiable {
    var id: String { name }
    let name: String
    var problems: [Problem]
}

// MARK: - Store

class TrackerStore: ObservableObject {
    @Published var algorithmCategories: [Category] = []
    @Published var dsCategories: [Category] = []
    @Published var filter: FilterMode = .all
    @Published var searchText: String = ""
    @Published var collapsedSections: Set<String> = []
    @Published var viewMode: ViewMode = .algorithm

    enum FilterMode: String, CaseIterable { case all, todo, done }
    enum ViewMode: String, CaseIterable { case algorithm, dataStructure }

    var categories: [Category] {
        get { viewMode == .algorithm ? algorithmCategories : dsCategories }
    }

    private var saveURL: URL {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".leetcode-tracker")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("progress.json")
    }

    init() {
        algorithmCategories = Self.defaultData()
        dsCategories = Self.dataStructureData()
        loadProgress()
    }

    /// All unique problems across both views (for progress tracking)
    private var allProblems: [(catIdx: Int, probIdx: Int, isAlgo: Bool)] {
        var result: [(Int, Int, Bool)] = []
        for ci in algorithmCategories.indices {
            for pi in algorithmCategories[ci].problems.indices {
                result.append((ci, pi, true))
            }
        }
        for ci in dsCategories.indices {
            for pi in dsCategories[ci].problems.indices {
                result.append((ci, pi, false))
            }
        }
        return result
    }

    func toggle(_ problemId: Int) {
        // Find current done state from algorithm view (source of truth)
        var newDone = true
        for cat in algorithmCategories {
            if let p = cat.problems.first(where: { $0.id == problemId }) {
                newDone = !p.done
                break
            }
        }
        // Update in both views
        for ci in algorithmCategories.indices {
            for pi in algorithmCategories[ci].problems.indices {
                if algorithmCategories[ci].problems[pi].id == problemId {
                    algorithmCategories[ci].problems[pi].done = newDone
                }
            }
        }
        for ci in dsCategories.indices {
            for pi in dsCategories[ci].problems.indices {
                if dsCategories[ci].problems[pi].id == problemId {
                    dsCategories[ci].problems[pi].done = newDone
                }
            }
        }
        saveProgress()
    }

    func toggleCollapse(_ name: String) {
        if collapsedSections.contains(name) { collapsedSections.remove(name) }
        else { collapsedSections.insert(name) }
    }

    var totalDone: Int {
        // Use algorithm categories as source of truth (no duplicates)
        algorithmCategories.flatMap(\.problems).filter(\.done).count
    }
    var totalCount: Int {
        algorithmCategories.flatMap(\.problems).count
    }

    func resetAll() {
        for ci in algorithmCategories.indices {
            for pi in algorithmCategories[ci].problems.indices {
                algorithmCategories[ci].problems[pi].done = false
            }
        }
        for ci in dsCategories.indices {
            for pi in dsCategories[ci].problems.indices {
                dsCategories[ci].problems[pi].done = false
            }
        }
        saveProgress()
    }

    private func saveProgress() {
        let doneIds = Set(algorithmCategories.flatMap(\.problems).filter(\.done).map(\.id))
        if let data = try? JSONEncoder().encode(Array(doneIds)) {
            try? data.write(to: saveURL)
        }
    }

    private func loadProgress() {
        guard let data = try? Data(contentsOf: saveURL),
              let ids = try? JSONDecoder().decode([Int].self, from: data) else { return }
        let doneSet = Set(ids)
        for ci in algorithmCategories.indices {
            for pi in algorithmCategories[ci].problems.indices {
                if doneSet.contains(algorithmCategories[ci].problems[pi].id) {
                    algorithmCategories[ci].problems[pi].done = true
                }
            }
        }
        for ci in dsCategories.indices {
            for pi in dsCategories[ci].problems.indices {
                if doneSet.contains(dsCategories[ci].problems[pi].id) {
                    dsCategories[ci].problems[pi].done = true
                }
            }
        }
    }

    static func defaultData() -> [Category] {
        [
            Category(name: "哈希", problems: [
                Problem(id: 1, name: "两数之和", difficulty: "简单", slug: "two-sum"),
                Problem(id: 49, name: "字母异位词分组", difficulty: "中等", slug: "group-anagrams"),
                Problem(id: 128, name: "最长连续序列", difficulty: "中等", slug: "longest-consecutive-sequence"),
            ]),
            Category(name: "双指针", problems: [
                Problem(id: 283, name: "移动零", difficulty: "简单", slug: "move-zeroes"),
                Problem(id: 11, name: "盛最多水的容器", difficulty: "中等", slug: "container-with-most-water"),
                Problem(id: 15, name: "三数之和", difficulty: "中等", slug: "3sum"),
                Problem(id: 42, name: "接雨水", difficulty: "困难", slug: "trapping-rain-water"),
            ]),
            Category(name: "滑动窗口", problems: [
                Problem(id: 3, name: "无重复字符的最长子串", difficulty: "中等", slug: "longest-substring-without-repeating-characters"),
                Problem(id: 438, name: "找到字符串中所有字母异位词", difficulty: "中等", slug: "find-all-anagrams-in-a-string"),
            ]),
            Category(name: "子串", problems: [
                Problem(id: 560, name: "和为 K 的子数组", difficulty: "中等", slug: "subarray-sum-equals-k"),
                Problem(id: 239, name: "滑动窗口最大值", difficulty: "困难", slug: "sliding-window-maximum"),
                Problem(id: 76, name: "最小覆盖子串", difficulty: "困难", slug: "minimum-window-substring"),
            ]),
            Category(name: "普通数组", problems: [
                Problem(id: 53, name: "最大子数组和", difficulty: "中等", slug: "maximum-subarray"),
                Problem(id: 56, name: "合并区间", difficulty: "中等", slug: "merge-intervals"),
                Problem(id: 189, name: "轮转数组", difficulty: "中等", slug: "rotate-array"),
                Problem(id: 238, name: "除自身以外数组的乘积", difficulty: "中等", slug: "product-of-array-except-self"),
                Problem(id: 41, name: "缺失的第一个正数", difficulty: "困难", slug: "first-missing-positive"),
            ]),
            Category(name: "矩阵", problems: [
                Problem(id: 73, name: "矩阵置零", difficulty: "中等", slug: "set-matrix-zeroes"),
                Problem(id: 54, name: "螺旋矩阵", difficulty: "中等", slug: "spiral-matrix"),
                Problem(id: 48, name: "旋转图像", difficulty: "中等", slug: "rotate-image"),
                Problem(id: 240, name: "搜索二维矩阵 II", difficulty: "中等", slug: "search-a-2d-matrix-ii"),
            ]),
            Category(name: "链表", problems: [
                Problem(id: 160, name: "相交链表", difficulty: "简单", slug: "intersection-of-two-linked-lists"),
                Problem(id: 206, name: "反转链表", difficulty: "简单", slug: "reverse-linked-list"),
                Problem(id: 234, name: "回文链表", difficulty: "简单", slug: "palindrome-linked-list"),
                Problem(id: 141, name: "环形链表", difficulty: "简单", slug: "linked-list-cycle"),
                Problem(id: 142, name: "环形链表 II", difficulty: "中等", slug: "linked-list-cycle-ii"),
                Problem(id: 21, name: "合并两个有序链表", difficulty: "简单", slug: "merge-two-sorted-lists"),
                Problem(id: 2, name: "两数相加", difficulty: "中等", slug: "add-two-numbers"),
                Problem(id: 19, name: "删除链表的倒数第 N 个结点", difficulty: "中等", slug: "remove-nth-node-from-end-of-list"),
                Problem(id: 24, name: "两两交换链表中的节点", difficulty: "中等", slug: "swap-nodes-in-pairs"),
                Problem(id: 25, name: "K 个一组翻转链表", difficulty: "困难", slug: "reverse-nodes-in-k-group"),
                Problem(id: 138, name: "随机链表的复制", difficulty: "中等", slug: "copy-list-with-random-pointer"),
                Problem(id: 148, name: "排序链表", difficulty: "中等", slug: "sort-list"),
                Problem(id: 23, name: "合并 K 个升序链表", difficulty: "困难", slug: "merge-k-sorted-lists"),
                Problem(id: 146, name: "LRU 缓存", difficulty: "中等", slug: "lru-cache"),
            ]),
            Category(name: "二叉树", problems: [
                Problem(id: 94, name: "二叉树的中序遍历", difficulty: "简单", slug: "binary-tree-inorder-traversal"),
                Problem(id: 104, name: "二叉树的最大深度", difficulty: "简单", slug: "maximum-depth-of-binary-tree"),
                Problem(id: 226, name: "翻转二叉树", difficulty: "简单", slug: "invert-binary-tree"),
                Problem(id: 101, name: "对称二叉树", difficulty: "简单", slug: "symmetric-tree"),
                Problem(id: 543, name: "二叉树的直径", difficulty: "简单", slug: "diameter-of-binary-tree"),
                Problem(id: 102, name: "二叉树的层序遍历", difficulty: "中等", slug: "binary-tree-level-order-traversal"),
                Problem(id: 108, name: "将有序数组转换为二叉搜索树", difficulty: "简单", slug: "convert-sorted-array-to-binary-search-tree"),
                Problem(id: 98, name: "验证二叉搜索树", difficulty: "中等", slug: "validate-binary-search-tree"),
                Problem(id: 230, name: "二叉搜索树中第K小的元素", difficulty: "中等", slug: "kth-smallest-element-in-a-bst"),
                Problem(id: 199, name: "二叉树的右视图", difficulty: "中等", slug: "binary-tree-right-side-view"),
                Problem(id: 114, name: "二叉树展开为链表", difficulty: "中等", slug: "flatten-binary-tree-to-linked-list"),
                Problem(id: 105, name: "从前序与中序遍历序列构造二叉树", difficulty: "中等", slug: "construct-binary-tree-from-preorder-and-inorder-traversal"),
                Problem(id: 437, name: "路径总和 III", difficulty: "中等", slug: "path-sum-iii"),
                Problem(id: 236, name: "二叉树的最近公共祖先", difficulty: "中等", slug: "lowest-common-ancestor-of-a-binary-tree"),
                Problem(id: 124, name: "二叉树中的最大路径和", difficulty: "困难", slug: "binary-tree-maximum-path-sum"),
            ]),
            Category(name: "图论", problems: [
                Problem(id: 200, name: "岛屿数量", difficulty: "中等", slug: "number-of-islands"),
                Problem(id: 994, name: "腐烂的橘子", difficulty: "中等", slug: "rotting-oranges"),
                Problem(id: 207, name: "课程表", difficulty: "中等", slug: "course-schedule"),
                Problem(id: 208, name: "实现 Trie (前缀树)", difficulty: "中等", slug: "implement-trie-prefix-tree"),
            ]),
            Category(name: "回溯", problems: [
                Problem(id: 46, name: "全排列", difficulty: "中等", slug: "permutations"),
                Problem(id: 78, name: "子集", difficulty: "中等", slug: "subsets"),
                Problem(id: 17, name: "电话号码的字母组合", difficulty: "中等", slug: "letter-combinations-of-a-phone-number"),
                Problem(id: 39, name: "组合总和", difficulty: "中等", slug: "combination-sum"),
                Problem(id: 22, name: "括号生成", difficulty: "中等", slug: "generate-parentheses"),
                Problem(id: 79, name: "单词搜索", difficulty: "中等", slug: "word-search"),
                Problem(id: 131, name: "分割回文串", difficulty: "中等", slug: "palindrome-partitioning"),
                Problem(id: 51, name: "N 皇后", difficulty: "困难", slug: "n-queens"),
            ]),
            Category(name: "二分查找", problems: [
                Problem(id: 35, name: "搜索插入位置", difficulty: "简单", slug: "search-insert-position"),
                Problem(id: 74, name: "搜索二维矩阵", difficulty: "中等", slug: "search-a-2d-matrix"),
                Problem(id: 34, name: "在排序数组中查找元素的第一个和最后一个位置", difficulty: "中等", slug: "find-first-and-last-position-of-element-in-sorted-array"),
                Problem(id: 33, name: "搜索旋转排序数组", difficulty: "中等", slug: "search-in-rotated-sorted-array"),
                Problem(id: 153, name: "寻找旋转排序数组中的最小值", difficulty: "中等", slug: "find-minimum-in-rotated-sorted-array"),
                Problem(id: 4, name: "寻找两个正序数组的中位数", difficulty: "困难", slug: "median-of-two-sorted-arrays"),
            ]),
            Category(name: "栈", problems: [
                Problem(id: 20, name: "有效的括号", difficulty: "简单", slug: "valid-parentheses"),
                Problem(id: 155, name: "最小栈", difficulty: "中等", slug: "min-stack"),
                Problem(id: 394, name: "字符串解码", difficulty: "中等", slug: "decode-string"),
                Problem(id: 739, name: "每日温度", difficulty: "中等", slug: "daily-temperatures"),
                Problem(id: 84, name: "柱状图中最大的矩形", difficulty: "困难", slug: "largest-rectangle-in-histogram"),
            ]),
            Category(name: "堆", problems: [
                Problem(id: 215, name: "数组中的第K个最大元素", difficulty: "中等", slug: "kth-largest-element-in-an-array"),
                Problem(id: 347, name: "前 K 个高频元素", difficulty: "中等", slug: "top-k-frequent-elements"),
                Problem(id: 295, name: "数据流的中位数", difficulty: "困难", slug: "find-median-from-data-stream"),
            ]),
            Category(name: "贪心算法", problems: [
                Problem(id: 121, name: "买卖股票的最佳时机", difficulty: "简单", slug: "best-time-to-buy-and-sell-stock"),
                Problem(id: 55, name: "跳跃游戏", difficulty: "中等", slug: "jump-game"),
                Problem(id: 45, name: "跳跃游戏 II", difficulty: "中等", slug: "jump-game-ii"),
                Problem(id: 763, name: "划分字母区间", difficulty: "中等", slug: "partition-labels"),
            ]),
            Category(name: "动态规划", problems: [
                Problem(id: 70, name: "爬楼梯", difficulty: "简单", slug: "climbing-stairs"),
                Problem(id: 118, name: "杨辉三角", difficulty: "简单", slug: "pascals-triangle"),
                Problem(id: 198, name: "打家劫舍", difficulty: "中等", slug: "house-robber"),
                Problem(id: 279, name: "完全平方数", difficulty: "中等", slug: "perfect-squares"),
                Problem(id: 322, name: "零钱兑换", difficulty: "中等", slug: "coin-change"),
                Problem(id: 139, name: "单词拆分", difficulty: "中等", slug: "word-break"),
                Problem(id: 300, name: "最长递增子序列", difficulty: "中等", slug: "longest-increasing-subsequence"),
                Problem(id: 152, name: "乘积最大子数组", difficulty: "中等", slug: "maximum-product-subarray"),
                Problem(id: 416, name: "分割等和子集", difficulty: "中等", slug: "partition-equal-subset-sum"),
                Problem(id: 32, name: "最长有效括号", difficulty: "困难", slug: "longest-valid-parentheses"),
            ]),
            Category(name: "多维动态规划", problems: [
                Problem(id: 62, name: "不同路径", difficulty: "中等", slug: "unique-paths"),
                Problem(id: 64, name: "最小路径和", difficulty: "中等", slug: "minimum-path-sum"),
                Problem(id: 5, name: "最长回文子串", difficulty: "中等", slug: "longest-palindromic-substring"),
                Problem(id: 1143, name: "最长公共子序列", difficulty: "中等", slug: "longest-common-subsequence"),
                Problem(id: 72, name: "编辑距离", difficulty: "中等", slug: "edit-distance"),
            ]),
            Category(name: "技巧", problems: [
                Problem(id: 136, name: "只出现一次的数字", difficulty: "简单", slug: "single-number"),
                Problem(id: 169, name: "多数元素", difficulty: "简单", slug: "majority-element"),
                Problem(id: 75, name: "颜色分类", difficulty: "中等", slug: "sort-colors"),
                Problem(id: 31, name: "下一个排列", difficulty: "中等", slug: "next-permutation"),
                Problem(id: 287, name: "寻找重复数", difficulty: "中等", slug: "find-the-duplicate-number"),
            ]),
        ]
    }

    static func dataStructureData() -> [Category] {
        [
            Category(name: "📦 数组", problems: [
                Problem(id: 1, name: "两数之和", difficulty: "简单", slug: "two-sum"),
                Problem(id: 283, name: "移动零", difficulty: "简单", slug: "move-zeroes"),
                Problem(id: 11, name: "盛最多水的容器", difficulty: "中等", slug: "container-with-most-water"),
                Problem(id: 15, name: "三数之和", difficulty: "中等", slug: "3sum"),
                Problem(id: 42, name: "接雨水", difficulty: "困难", slug: "trapping-rain-water"),
                Problem(id: 53, name: "最大子数组和", difficulty: "中等", slug: "maximum-subarray"),
                Problem(id: 56, name: "合并区间", difficulty: "中等", slug: "merge-intervals"),
                Problem(id: 189, name: "轮转数组", difficulty: "中等", slug: "rotate-array"),
                Problem(id: 238, name: "除自身以外数组的乘积", difficulty: "中等", slug: "product-of-array-except-self"),
                Problem(id: 41, name: "缺失的第一个正数", difficulty: "困难", slug: "first-missing-positive"),
                Problem(id: 136, name: "只出现一次的数字", difficulty: "简单", slug: "single-number"),
                Problem(id: 169, name: "多数元素", difficulty: "简单", slug: "majority-element"),
                Problem(id: 75, name: "颜色分类", difficulty: "中等", slug: "sort-colors"),
                Problem(id: 31, name: "下一个排列", difficulty: "中等", slug: "next-permutation"),
                Problem(id: 287, name: "寻找重复数", difficulty: "中等", slug: "find-the-duplicate-number"),
                Problem(id: 121, name: "买卖股票的最佳时机", difficulty: "简单", slug: "best-time-to-buy-and-sell-stock"),
                Problem(id: 55, name: "跳跃游戏", difficulty: "中等", slug: "jump-game"),
                Problem(id: 45, name: "跳跃游戏 II", difficulty: "中等", slug: "jump-game-ii"),
                Problem(id: 763, name: "划分字母区间", difficulty: "中等", slug: "partition-labels"),
                Problem(id: 35, name: "搜索插入位置", difficulty: "简单", slug: "search-insert-position"),
                Problem(id: 34, name: "在排序数组中查找元素的第一个和最后一个位置", difficulty: "中等", slug: "find-first-and-last-position-of-element-in-sorted-array"),
                Problem(id: 33, name: "搜索旋转排序数组", difficulty: "中等", slug: "search-in-rotated-sorted-array"),
                Problem(id: 153, name: "寻找旋转排序数组中的最小值", difficulty: "中等", slug: "find-minimum-in-rotated-sorted-array"),
                Problem(id: 4, name: "寻找两个正序数组的中位数", difficulty: "困难", slug: "median-of-two-sorted-arrays"),
                Problem(id: 152, name: "乘积最大子数组", difficulty: "中等", slug: "maximum-product-subarray"),
                Problem(id: 300, name: "最长递增子序列", difficulty: "中等", slug: "longest-increasing-subsequence"),
                Problem(id: 416, name: "分割等和子集", difficulty: "中等", slug: "partition-equal-subset-sum"),
            ]),
            Category(name: "🔤 字符串", problems: [
                Problem(id: 3, name: "无重复字符的最长子串", difficulty: "中等", slug: "longest-substring-without-repeating-characters"),
                Problem(id: 438, name: "找到字符串中所有字母异位词", difficulty: "中等", slug: "find-all-anagrams-in-a-string"),
                Problem(id: 76, name: "最小覆盖子串", difficulty: "困难", slug: "minimum-window-substring"),
                Problem(id: 49, name: "字母异位词分组", difficulty: "中等", slug: "group-anagrams"),
                Problem(id: 5, name: "最长回文子串", difficulty: "中等", slug: "longest-palindromic-substring"),
                Problem(id: 1143, name: "最长公共子序列", difficulty: "中等", slug: "longest-common-subsequence"),
                Problem(id: 72, name: "编辑距离", difficulty: "中等", slug: "edit-distance"),
                Problem(id: 394, name: "字符串解码", difficulty: "中等", slug: "decode-string"),
                Problem(id: 20, name: "有效的括号", difficulty: "简单", slug: "valid-parentheses"),
                Problem(id: 32, name: "最长有效括号", difficulty: "困难", slug: "longest-valid-parentheses"),
                Problem(id: 22, name: "括号生成", difficulty: "中等", slug: "generate-parentheses"),
                Problem(id: 17, name: "电话号码的字母组合", difficulty: "中等", slug: "letter-combinations-of-a-phone-number"),
                Problem(id: 131, name: "分割回文串", difficulty: "中等", slug: "palindrome-partitioning"),
                Problem(id: 139, name: "单词拆分", difficulty: "中等", slug: "word-break"),
            ]),
            Category(name: "#️⃣ 哈希表", problems: [
                Problem(id: 1, name: "两数之和", difficulty: "简单", slug: "two-sum"),
                Problem(id: 49, name: "字母异位词分组", difficulty: "中等", slug: "group-anagrams"),
                Problem(id: 128, name: "最长连续序列", difficulty: "中等", slug: "longest-consecutive-sequence"),
                Problem(id: 560, name: "和为 K 的子数组", difficulty: "中等", slug: "subarray-sum-equals-k"),
                Problem(id: 438, name: "找到字符串中所有字母异位词", difficulty: "中等", slug: "find-all-anagrams-in-a-string"),
                Problem(id: 76, name: "最小覆盖子串", difficulty: "困难", slug: "minimum-window-substring"),
                Problem(id: 146, name: "LRU 缓存", difficulty: "中等", slug: "lru-cache"),
                Problem(id: 347, name: "前 K 个高频元素", difficulty: "中等", slug: "top-k-frequent-elements"),
            ]),
            Category(name: "🔗 链表", problems: [
                Problem(id: 160, name: "相交链表", difficulty: "简单", slug: "intersection-of-two-linked-lists"),
                Problem(id: 206, name: "反转链表", difficulty: "简单", slug: "reverse-linked-list"),
                Problem(id: 234, name: "回文链表", difficulty: "简单", slug: "palindrome-linked-list"),
                Problem(id: 141, name: "环形链表", difficulty: "简单", slug: "linked-list-cycle"),
                Problem(id: 142, name: "环形链表 II", difficulty: "中等", slug: "linked-list-cycle-ii"),
                Problem(id: 21, name: "合并两个有序链表", difficulty: "简单", slug: "merge-two-sorted-lists"),
                Problem(id: 2, name: "两数相加", difficulty: "中等", slug: "add-two-numbers"),
                Problem(id: 19, name: "删除链表的倒数第 N 个结点", difficulty: "中等", slug: "remove-nth-node-from-end-of-list"),
                Problem(id: 24, name: "两两交换链表中的节点", difficulty: "中等", slug: "swap-nodes-in-pairs"),
                Problem(id: 25, name: "K 个一组翻转链表", difficulty: "困难", slug: "reverse-nodes-in-k-group"),
                Problem(id: 138, name: "随机链表的复制", difficulty: "中等", slug: "copy-list-with-random-pointer"),
                Problem(id: 148, name: "排序链表", difficulty: "中等", slug: "sort-list"),
                Problem(id: 23, name: "合并 K 个升序链表", difficulty: "困难", slug: "merge-k-sorted-lists"),
                Problem(id: 146, name: "LRU 缓存", difficulty: "中等", slug: "lru-cache"),
                Problem(id: 114, name: "二叉树展开为链表", difficulty: "中等", slug: "flatten-binary-tree-to-linked-list"),
            ]),
            Category(name: "📚 栈 / 队列", problems: [
                Problem(id: 20, name: "有效的括号", difficulty: "简单", slug: "valid-parentheses"),
                Problem(id: 155, name: "最小栈", difficulty: "中等", slug: "min-stack"),
                Problem(id: 394, name: "字符串解码", difficulty: "中等", slug: "decode-string"),
                Problem(id: 739, name: "每日温度", difficulty: "中等", slug: "daily-temperatures"),
                Problem(id: 84, name: "柱状图中最大的矩形", difficulty: "困难", slug: "largest-rectangle-in-histogram"),
                Problem(id: 239, name: "滑动窗口最大值", difficulty: "困难", slug: "sliding-window-maximum"),
                Problem(id: 102, name: "二叉树的层序遍历", difficulty: "中等", slug: "binary-tree-level-order-traversal"),
                Problem(id: 994, name: "腐烂的橘子", difficulty: "中等", slug: "rotting-oranges"),
            ]),
            Category(name: "🌳 二叉树 / BST", problems: [
                Problem(id: 94, name: "二叉树的中序遍历", difficulty: "简单", slug: "binary-tree-inorder-traversal"),
                Problem(id: 104, name: "二叉树的最大深度", difficulty: "简单", slug: "maximum-depth-of-binary-tree"),
                Problem(id: 226, name: "翻转二叉树", difficulty: "简单", slug: "invert-binary-tree"),
                Problem(id: 101, name: "对称二叉树", difficulty: "简单", slug: "symmetric-tree"),
                Problem(id: 543, name: "二叉树的直径", difficulty: "简单", slug: "diameter-of-binary-tree"),
                Problem(id: 102, name: "二叉树的层序遍历", difficulty: "中等", slug: "binary-tree-level-order-traversal"),
                Problem(id: 108, name: "将有序数组转换为二叉搜索树", difficulty: "简单", slug: "convert-sorted-array-to-binary-search-tree"),
                Problem(id: 98, name: "验证二叉搜索树", difficulty: "中等", slug: "validate-binary-search-tree"),
                Problem(id: 230, name: "二叉搜索树中第K小的元素", difficulty: "中等", slug: "kth-smallest-element-in-a-bst"),
                Problem(id: 199, name: "二叉树的右视图", difficulty: "中等", slug: "binary-tree-right-side-view"),
                Problem(id: 114, name: "二叉树展开为链表", difficulty: "中等", slug: "flatten-binary-tree-to-linked-list"),
                Problem(id: 105, name: "从前序与中序遍历序列构造二叉树", difficulty: "中等", slug: "construct-binary-tree-from-preorder-and-inorder-traversal"),
                Problem(id: 437, name: "路径总和 III", difficulty: "中等", slug: "path-sum-iii"),
                Problem(id: 236, name: "二叉树的最近公共祖先", difficulty: "中等", slug: "lowest-common-ancestor-of-a-binary-tree"),
                Problem(id: 124, name: "二叉树中的最大路径和", difficulty: "困难", slug: "binary-tree-maximum-path-sum"),
                Problem(id: 208, name: "实现 Trie (前缀树)", difficulty: "中等", slug: "implement-trie-prefix-tree"),
            ]),
            Category(name: "🗺️ 图", problems: [
                Problem(id: 200, name: "岛屿数量", difficulty: "中等", slug: "number-of-islands"),
                Problem(id: 994, name: "腐烂的橘子", difficulty: "中等", slug: "rotting-oranges"),
                Problem(id: 207, name: "课程表", difficulty: "中等", slug: "course-schedule"),
                Problem(id: 79, name: "单词搜索", difficulty: "中等", slug: "word-search"),
                Problem(id: 51, name: "N 皇后", difficulty: "困难", slug: "n-queens"),
            ]),
            Category(name: "⛰️ 堆 / 优先队列", problems: [
                Problem(id: 215, name: "数组中的第K个最大元素", difficulty: "中等", slug: "kth-largest-element-in-an-array"),
                Problem(id: 347, name: "前 K 个高频元素", difficulty: "中等", slug: "top-k-frequent-elements"),
                Problem(id: 295, name: "数据流的中位数", difficulty: "困难", slug: "find-median-from-data-stream"),
                Problem(id: 23, name: "合并 K 个升序链表", difficulty: "困难", slug: "merge-k-sorted-lists"),
            ]),
            Category(name: "🔢 矩阵 (二维数组)", problems: [
                Problem(id: 73, name: "矩阵置零", difficulty: "中等", slug: "set-matrix-zeroes"),
                Problem(id: 54, name: "螺旋矩阵", difficulty: "中等", slug: "spiral-matrix"),
                Problem(id: 48, name: "旋转图像", difficulty: "中等", slug: "rotate-image"),
                Problem(id: 240, name: "搜索二维矩阵 II", difficulty: "中等", slug: "search-a-2d-matrix-ii"),
                Problem(id: 74, name: "搜索二维矩阵", difficulty: "中等", slug: "search-a-2d-matrix"),
                Problem(id: 62, name: "不同路径", difficulty: "中等", slug: "unique-paths"),
                Problem(id: 64, name: "最小路径和", difficulty: "中等", slug: "minimum-path-sum"),
            ]),
        ]
    }
}

// MARK: - SwiftUI Views

func diffColor(_ d: String) -> Color {
    switch d {
    case "简单": return .green
    case "中等": return .yellow
    case "困难": return .red
    default: return .gray
    }
}

struct ProblemRow: View {
    let problem: Problem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onToggle) {
                Image(systemName: problem.done ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(problem.done ? .green : .gray)
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)

            Text("\(problem.id).")
                .foregroundColor(.secondary)
                .font(.system(size: 12, design: .monospaced))
                .frame(width: 40, alignment: .trailing)

            Text(problem.name)
                .font(.system(size: 13))
                .foregroundColor(problem.done ? .secondary : .primary)
                .strikethrough(problem.done)
                .lineLimit(1)
                .onTapGesture {
                    if let url = URL(string: "https://leetcode.cn/problems/\(problem.slug)/") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .onHover { hovering in
                    if hovering { NSCursor.pointingHand.push() }
                    else { NSCursor.pop() }
                }

            Spacer()

            Text(problem.difficulty)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(diffColor(problem.difficulty))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}

struct CategorySection: View {
    let category: Category
    let isCollapsed: Bool
    let onToggleCollapse: () -> Void
    let onToggleProblem: (Int) -> Void
    let filter: TrackerStore.FilterMode
    let searchText: String

    var filteredProblems: [Problem] {
        var list = category.problems
        let q = searchText.lowercased()
        if !q.isEmpty {
            list = list.filter { $0.name.lowercased().contains(q) || String($0.id).contains(q) }
        }
        switch filter {
        case .all: break
        case .done: list = list.filter(\.done)
        case .todo: list = list.filter { !$0.done }
        }
        return list
    }

    var body: some View {
        let problems = filteredProblems
        if problems.isEmpty { EmptyView() }
        else {
            VStack(spacing: 0) {
                // Header
                Button(action: onToggleCollapse) {
                    HStack {
                        Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 14)
                        Text(category.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        Spacer()
                        let done = category.problems.filter(\.done).count
                        Text("\(done)/\(category.problems.count)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if !isCollapsed {
                    ForEach(problems) { p in
                        ProblemRow(problem: p) { onToggleProblem(p.id) }
                        if p.id != problems.last?.id {
                            Divider().padding(.leading, 44).opacity(0.3)
                        }
                    }
                }
            }
            .background(Color.white.opacity(0.04))
            .cornerRadius(10)
        }
    }
}

struct TrackerView: View {
    @ObservedObject var store: TrackerStore

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("🔥")
                    .font(.system(size: 16))
                Text("LeetCode 热题 100")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                let pct = store.totalCount > 0 ? Int(Double(store.totalDone) / Double(store.totalCount) * 100) : 0
                Text("\(store.totalDone)/\(store.totalCount)")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(.orange)
                Text("\(pct)%")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 6)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(store.totalDone) / max(CGFloat(store.totalCount), 1))
                        .animation(.easeInOut(duration: 0.3), value: store.totalDone)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 14)
            .padding(.bottom, 8)

            // View mode toggle
            HStack(spacing: 0) {
                ForEach(TrackerStore.ViewMode.allCases, id: \.self) { mode in
                    let label: String = { switch mode { case .algorithm: return "📋 算法分类"; case .dataStructure: return "🧱 数据结构" } }()
                    Button(action: { withAnimation(.easeInOut(duration: 0.2)) { store.viewMode = mode } }) {
                        Text(label)
                            .font(.system(size: 12, weight: store.viewMode == mode ? .bold : .regular))
                            .foregroundColor(store.viewMode == mode ? .white : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .background(store.viewMode == mode ? Color.blue.opacity(0.5) : Color.clear)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(2)
            .background(Color.white.opacity(0.06))
            .cornerRadius(8)
            .padding(.horizontal, 14)
            .padding(.bottom, 8)

            // Filter + Search
            HStack(spacing: 6) {
                ForEach(TrackerStore.FilterMode.allCases, id: \.self) { mode in
                    let label: String = { switch mode { case .all: return "全部"; case .todo: return "未完成"; case .done: return "已完成" } }()
                    Button(label) { store.filter = mode }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: store.filter == mode ? .bold : .regular))
                        .foregroundColor(store.filter == mode ? .white : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(store.filter == mode ? Color.orange.opacity(0.6) : Color.clear)
                        .cornerRadius(6)
                }
                Spacer()
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 11))
                TextField("搜索", text: $store.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .frame(width: 80)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 8)

            Divider().opacity(0.3)

            // Problem list
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(store.categories) { cat in
                        CategorySection(
                            category: cat,
                            isCollapsed: store.collapsedSections.contains(cat.name),
                            onToggleCollapse: { store.toggleCollapse(cat.name) },
                            onToggleProblem: { store.toggle($0) },
                            filter: store.filter,
                            searchText: store.searchText
                        )
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
        }
    }
}

// MARK: - Floating Panel

class FloatingPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isOpaque = false
        backgroundColor = .clear
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        hasShadow = true

        // Vibrancy
        let vfx = NSVisualEffectView(frame: contentRect)
        vfx.material = .hudWindow
        vfx.blendingMode = .behindWindow
        vfx.state = .active
        vfx.wantsLayer = true
        vfx.layer?.cornerRadius = 16
        vfx.layer?.masksToBounds = true
        contentView = vfx
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: FloatingPanel?
    var statusItem: NSStatusItem?
    let store = TrackerStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu bar icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let btn = statusItem?.button {
            btn.title = "🔥"
        }
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "显示/隐藏", action: #selector(togglePanel), keyEquivalent: "l"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "重置进度", action: #selector(resetProgress), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q"))
        statusItem?.menu = menu

        // Floating window
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let w: CGFloat = 360
        let h: CGFloat = 580
        let x = screenFrame.maxX - w - 20
        let y = screenFrame.maxY - h - 20
        let rect = NSRect(x: x, y: y, width: w, height: h)

        panel = FloatingPanel(contentRect: rect)
        let hostView = NSHostingView(rootView: TrackerView(store: store))
        hostView.translatesAutoresizingMaskIntoConstraints = false
        panel?.contentView?.addSubview(hostView)
        if let cv = panel?.contentView {
            NSLayoutConstraint.activate([
                hostView.topAnchor.constraint(equalTo: cv.topAnchor),
                hostView.bottomAnchor.constraint(equalTo: cv.bottomAnchor),
                hostView.leadingAnchor.constraint(equalTo: cv.leadingAnchor),
                hostView.trailingAnchor.constraint(equalTo: cv.trailingAnchor),
            ])
        }
        panel?.orderFront(nil)
    }

    @objc func togglePanel() {
        if panel?.isVisible == true { panel?.orderOut(nil) }
        else { panel?.orderFront(nil) }
    }
    @objc func resetProgress() {
        let alert = NSAlert()
        alert.messageText = "确定重置所有进度？"
        alert.addButton(withTitle: "重置")
        alert.addButton(withTitle: "取消")
        if alert.runModal() == .alertFirstButtonReturn {
            store.resetAll()
        }
    }
    @objc func quit() { NSApp.terminate(nil) }
}

// MARK: - Entry

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
