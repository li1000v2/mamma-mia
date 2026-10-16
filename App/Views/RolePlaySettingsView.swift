import SwiftUI
import MammaCore

/// 在线对话设置: the learner's own Google key and project for the online role-play, the reply
/// model and the daily cap. The key goes into the Keychain and is never shown again in full.
struct RolePlaySettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var pastedKey = ""
    @State private var project = ""
    @State private var keyMessage: String?
    @State private var testing = false
    @State private var testResult: String?
    @State private var testPassed = false

    private var service: RolePlayService { model.rolePlay }

    var body: some View {
        List {
            keySection
            Section {
                Picker("回复模型", selection: Binding(get: { service.replyModel }, set: { service.setReplyModel($0) })) {
                    Text("Gemini 4 Argon").tag(ReplyModel.argon)
                    Text("Gemini 3.8 Flash").tag(ReplyModel.flash)
                }
            } header: {
                Text("回复")
            } footer: {
                Text("Argon 说得更自然，开口前通常要等 2–4 秒，偶尔更久；Flash 快一些（约 1 秒）。等的时候先播一个语气词垫着。反馈卡总是用 Argon。")
            }
            Section {
                Stepper(value: Binding(get: { service.allowance.dailyLimit }, set: { service.setDailyLimit($0) }),
                        in: TurnAllowance.limits, step: 10) {
                    Text("每天最多 \(service.allowance.dailyLimit) 个回合")
                }
                LabeledContent("今天已用", value: "\(service.used(on: model.today)) 个回合")
            } header: {
                Text("每日上限")
            } footer: {
                Text("你说一句、对方回一句算一个回合；一场对话最多 \(RolePlayConversation.turnsPerSession) 个回合。默认上限是两场。开场白和反馈卡不算。")
            }
            Section("会发给 Google 的内容") {
                Text("手机识别出的你说的话（文字，不是录音）、角色设定和对话记录。录音、行程、酒店和忌口都不会发出去。key 只存在这台手机的钥匙串里，不进备份。")
                    .font(.callout)
            }
        }
        .navigationTitle("在线对话设置")
        .onAppear {
            project = service.project
        }
    }

    private var keySection: some View {
        Section {
            if service.hasKey {
                LabeledContent("已保存的 key", value: "…\(service.keySuffix ?? "")")
                Button("删除 key", role: .destructive) {
                    service.deleteKey()
                    testResult = nil
                }
            }
            SecureField(service.hasKey ? "粘贴新的 key 替换" : "粘贴 Google API key", text: $pastedKey)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !pastedKey.isEmpty {
                Button("保存 key") {
                    keyMessage = service.saveKey(pastedKey) ?? "已保存到钥匙串。"
                    pastedKey = ""
                    testResult = nil
                }
            }
            if let keyMessage {
                Text(keyMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            TextField("项目编号（一串数字）", text: $project)
                .keyboardType(.numbersAndPunctuation)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit { service.setProject(project) }
                .onChange(of: project) { service.setProject(project) }
            if !project.isEmpty, GeminiEndpoint(project: project) == nil {
                Text("项目编号只能是数字（或小写字母、数字和连字符的项目 ID）。")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            Button {
                Task {
                    testing = true
                    testResult = await service.testConnection()
                    testPassed = testResult == nil
                    testing = false
                }
            } label: {
                if testing {
                    ProgressView()
                } else {
                    Label("测试连接", systemImage: "antenna.radiowaves.left.and.right")
                }
            }
            .disabled(!service.isConfigured || testing)
            if testPassed, testResult == nil, !testing {
                Label("连上了，可以开始对话。", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.footnote)
            } else if let testResult {
                Text(testResult)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            if let refusal = service.refusal, testResult == nil {
                Text("上次被拒绝：\(refusal) 改好设置后点「测试连接」，通过了才会再发请求。")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        } header: {
            Text("Google Cloud")
        } footer: {
            Text("用 Google Cloud 控制台里 Agent Platform 的 API key 和项目编号。建议把 key 限制为只能调用 Agent Platform API，并给结算账号设预算提醒。如果 key 限定了 iOS 应用，要允许的 bundle ID 是 \(service.bundleID)。")
        }
    }
}
