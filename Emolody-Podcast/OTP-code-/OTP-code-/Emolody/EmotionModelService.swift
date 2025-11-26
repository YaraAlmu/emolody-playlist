//
//  EmotionModelService.swift
//  Emolody
//
//  Created by toleen alghamdi on 13/04/1447 AH.
//
import Foundation
import AVFoundation
import CoreML

/// نحمل الـ mlmodel ديناميكياً من الباندل بدون الاعتماد على كلاس تلقائي
/// عشان نتفادى مشكلة "Cannot find type 'ExpressionClassifier' in scope"
final class EmotionModelService {

    static let shared = EmotionModelService()  // استخدمي .shared في CameraService
    private let model: MLModel
    private let inputName: String  // اسم خانة الإدخال (image/data) نحدده من الوصف

    private init?() {
        // غيّري الاسم هنا لو اسم ملفك مختلف
        let candidateNames = ["ExpressionClassifier", "EmotionClassifier", "Expression", "Model"]
        var url: URL? = nil
        for name in candidateNames {
            if let u = Bundle.main.url(forResource: name, withExtension: "mlmodelc") {
                url = u; break
            }
        }
        guard let modelURL = url, let ml = try? MLModel(contentsOf: modelURL) else {
            return nil
        }
        model = ml

        // نستخرج أول مدخل من النوع صورة (أو أول مفتاح إذا ما لقينا)
        if let (key, desc) = model.modelDescription.inputDescriptionsByName.first(where: { $0.value.type == .image }) {
            inputName = key
        } else {
            inputName = model.modelDescription.inputDescriptionsByName.keys.first ?? "image"
        }
    }

    /// يرجّع (التسمية, الثقة 0..1) أو nil لو فشل
    func predict(from sampleBuffer: CMSampleBuffer, isFront: Bool) -> (label: String, confidence: Float)? {
        guard let pixel = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }

        // لو حابة تعكسي للكاميرا الأمامية قد تحتاجين معالجة؛ نتركها الآن كما هي
        // build feature provider
        guard let provider = try? MLDictionaryFeatureProvider(
            dictionary: [inputName: MLFeatureValue(pixelBuffer: pixel)]
        ) else { return nil }

        guard let out = try? model.prediction(from: provider) else { return nil }

        // نقرأ classLabel و classLabelProbs (أسماء شائعة). إذا تختلف عندك يتعدل هنا.
        var label: String = "Neutral"
        var conf: Float = 0.3

        if let lbl = out.featureValue(for: "classLabel")?.stringValue {
            label = lbl
            if let probs = out.featureValue(for: "classLabelProbs")?.dictionaryValue as? [String: NSNumber],
               let p = probs[lbl]?.floatValue {
                conf = max(0.05, min(1.0, p))
            }
        } else if let probs = out.featureValue(for: "classLabelProbs")?.dictionaryValue as? [String: NSNumber],
                  let best = probs.max(by: { $0.value.floatValue < $1.value.floatValue }) {
            label = best.key
            conf = best.value.floatValue
        }

        return (mapToFourClasses(label), conf)
    }

    /// لو موديلك فيه 7 مشاعر، نلمّها لأربع تسميات
    private func mapToFourClasses(_ raw: String) -> String {
        let l = raw.lowercased()
        if l.contains("happy") || l.contains("smile") { return "Happy" }
        if l.contains("sad") { return "Sad" }
        if l.contains("angry") || l.contains("disgust") { return "Angry" }
        if l.contains("surprise") { return "Surprised" }
        return "Neutral"
    }
}
