import SwiftUI
import MammaCore

struct TodayView: View {
    @Environment(AppModel.self) private var model
    @State private var editingTrip = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Buongiorno!")
                            .font(.largeTitle.bold())
                        Text("每天 15 分钟：先复习，再学新课。忙的日子做 5 分钟复习也算。")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                if let error = model.loadError ?? model.storageError {
                    Section("出错了") {
                        Text(error)
                            .font(.footnote.monospaced())
                    }
                }

                tripSection

                if model.content != nil {
                    reviewSection
                    nextSection
                    statsSection
                }

                Section {
                    NavigationLink("诊断、日志与备份") { DiagnosticsView() }
                }
            }
            .navigationTitle("今日")
            .sheet(isPresented: $editingTrip) {
                TripEditorSheet()
                    .environment(model)
            }
        }
    }

    @ViewBuilder
    private var tripSection: some View {
        if let trip = model.trip {
            Section("行程") {
                TripStatus(trip: trip)
            }
        } else {
            Section {
                Button {
                    editingTrip = true
                } label: {
                    Label("填写行程", systemImage: "airplane")
                }
            } header: {
                Text("行程")
            } footer: {
                Text("填了每座城市的到达日期，复习会赶在用到之前，把要用的句子提前过一遍。以后在「随身」里修改。")
            }
        }
    }

    private var reviewSection: some View {
        let plan = model.todayPlan
        return Section("复习") {
            if plan.due.isEmpty && plan.boosted.isEmpty && plan.packed.isEmpty && plan.new.isEmpty {
                Label("今天的复习都做完了", systemImage: "checkmark.circle")
                    .foregroundStyle(.secondary)
            } else {
                NavigationLink {
                    ReviewSessionView()
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("开始复习")
                            .font(.headline)
                        Text(planSummary(plan))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    /// "到期 12 张 · 行程加练 5 张 · 城市包 20 张 · 新卡 10 张"; the trip's counts only appear near it.
    private func planSummary(_ plan: DailyPlan) -> String {
        var parts = ["到期 \(plan.due.count) 张"]
        if !plan.boosted.isEmpty {
            parts.append("行程加练 \(plan.boosted.count) 张")
        }
        if !plan.packed.isEmpty {
            parts.append("城市包 \(plan.packed.count) 张")
        }
        parts.append("新卡 \(plan.new.count) 张")
        return parts.joined(separator: " · ")
    }

    @ViewBuilder
    private var nextSection: some View {
        if let planner = model.planner {
            let lesson = planner.nextLesson(in: model.progress)
            let challenges = planner.readyChallenges(in: model.progress)
            Section("接下来") {
                if let lesson {
                    UnitLink(unit: lesson)
                } else {
                    Label("30 课都学完了", systemImage: "star.fill")
                }
                ForEach(challenges) { unit in
                    UnitLink(unit: unit)
                }
            }
        }
    }

    private var statsSection: some View {
        Section("记录") {
            LabeledContent("今天复习", value: "\(model.reviewsToday) 次")
            LabeledContent("学完的课", value: "\(model.progress.completedUnits.count) / 30")
            LabeledContent("通关的挑战", value: "\(Set(model.progress.challengeRuns.filter(\.passed).map(\.unit)).count) / 10")
        }
    }
}
