import SwiftUI

struct ContentView: View {
    @State private var startTime: Date = {
        let stored = UserDefaults.standard.object(forKey: "startTime") as? Date
        if let stored { return stored }
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: Date())
        comps.hour = 21
        comps.minute = 0
        comps.second = 0
        return cal.date(from: comps) ?? Date()
    }()
    @State private var intervalText: String = {
        let stored = UserDefaults.standard.double(forKey: "shootingInterval")
        return stored > 0 ? String(stored) : "22"
    }()
    @State private var now: Date = Date()
    @FocusState private var intervalFocused: Bool

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var interval: Double {
        Double(intervalText) ?? 0
    }

    private var secondsUntilStart: Double {
        startTime.timeIntervalSince(now)
    }

    private var preMoveShots: Double? {
        ShotCalculator.preMoveShots(interval: interval, secondsUntilStart: secondsUntilStart)
    }

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {
                    header
                    inputSection
                    resultsSection
                    Spacer(minLength: 20)
                }
                .frame(minHeight: geo.size.height)
                .padding(.horizontal, horizontalPadding(geo))
            }
        }
        .onReceive(timer) { t in
            now = t
        }
        .onTapGesture {
            intervalFocused = false
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    private var header: some View {
        VStack(spacing: 4) {
            Image(systemName: "camera.aperture")
                .font(.system(size: 40))
                .foregroundColor(.blue)
                .padding(.top, 24)
            Text("Timelapse Delay Tracker")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text("Pre-move shot calculator")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 24)
    }

    private var inputSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Setup")
            VStack(spacing: 0) {
                HStack {
                    Label("Move Start Time", systemImage: "clock")
                        .font(.body)
                    Spacer()
                    DatePicker("", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .onChange(of: startTime) { _, newVal in
                            UserDefaults.standard.set(newVal, forKey: "startTime")
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider().padding(.leading, 16)

                HStack {
                    Label("Shooting Interval", systemImage: "timer")
                        .font(.body)
                    Spacer()
                    TextField("seconds", text: $intervalText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .focused($intervalFocused)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    intervalFocused = false
                                    if let val = Double(intervalText), val > 0 {
                                        UserDefaults.standard.set(val, forKey: "shootingInterval")
                                    }
                                }
                            }
                        }
                        .onChange(of: intervalText) { _, newVal in
                            if let val = Double(newVal), val > 0 {
                                UserDefaults.standard.set(val, forKey: "shootingInterval")
                            }
                        }
                    Text("sec")
                        .foregroundColor(.secondary)
                        .font(.body)
                }
                .contentShape(Rectangle())
                .onTapGesture { intervalFocused = true }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.bottom, 20)
    }

    private var resultsSection: some View {
        VStack(spacing: 0) {
            sectionHeader("Live Results")
            VStack(spacing: 0) {
                if let shots = preMoveShots {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                            .frame(width: 32, height: 32)
                            .background(Color.blue.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pre-Move Shots Needed")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Enter \(ShotCalculator.rigShotCount(shots)) into rig")
                                .font(.caption)
                                .foregroundColor(.secondary.opacity(0.8))
                        }

                        Spacer()

                        Text(String(format: "%.1f", shots))
                            .font(.title3.monospacedDigit().bold())
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                } else {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .frame(width: 28, height: 28)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .padding(.trailing, 8)
                        Text(secondsUntilStart <= 0 ? "Start time has already passed" : "Enter a valid shooting interval")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.footnote.bold())
                .foregroundColor(.secondary)
                .padding(.leading, 4)
            Spacer()
        }
        .padding(.bottom, 6)
    }

    private func horizontalPadding(_ geo: GeometryProxy) -> CGFloat {
        let width = geo.size.width
        if width > 700 {
            return (width - 640) / 2
        }
        return 16
    }
}

#Preview {
    ContentView()
}
