import Foundation
import HealthKit

/// Apple Health integration — read weight + steps, write logged weight back.
/// The genuinely-native win for a fitness app.
@MainActor
final class HealthService: ObservableObject {
    static let shared = HealthService()
    private let store = HKHealthStore()

    @Published var steps: Int = 0
    @Published var connected = false

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
    private let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

    func connect() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: [weightType], read: [weightType, stepType])
            connected = true
            await refreshSteps()
            return true
        } catch {
            return false
        }
    }

    func latestWeightKg() async -> Double? {
        await withCheckedContinuation { cont in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let q = HKSampleQuery(sampleType: weightType, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                let kg = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: .gramUnit(with: .kilo))
                cont.resume(returning: kg)
            }
            store.execute(q)
        }
    }

    func saveWeight(_ kg: Double) {
        guard isAvailable else { return }
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg)
        let sample = HKQuantitySample(type: weightType, quantity: quantity, start: Date(), end: Date())
        store.save(sample) { _, _ in }
    }

    func refreshSteps() async {
        let start = Calendar.current.startOfDay(for: Date())
        let pred = HKQuery.predicateForSamples(withStart: start, end: Date())
        let sum: Double? = await withCheckedContinuation { cont in
            let q = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: pred, options: .cumulativeSum) { _, stats, _ in
                cont.resume(returning: stats?.sumQuantity()?.doubleValue(for: .count()))
            }
            store.execute(q)
        }
        steps = Int(sum ?? 0)
    }
}
