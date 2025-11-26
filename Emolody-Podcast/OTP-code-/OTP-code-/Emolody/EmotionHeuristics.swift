//
//  EmotionHeuristics.swift
//  Emolody
//
//  Created by toleen alghamdi on 13/04/1447 AH.
//
import Vision
import CoreGraphics
import SwiftUI

/// خوارزميات هندسية بسيطة (بدون نماذج) لاستخراج "سعادة/مفاجأة/حزن/محايد"
struct EmotionHeuristics {

    static func analyze(landmarks: VNFaceLandmarks2D,
                        boundingBox: CGRect) -> (label: String, confidence: CGFloat) {

        // تحويل مناطق معالم الوجه إلى نقاط CGPoint
        func pts(_ r: VNFaceLandmarkRegion2D?) -> [CGPoint] {
            guard let r = r else { return [] }
            return (0..<r.pointCount).map {
                let p = r.normalizedPoints[$0]
                return CGPoint(x: CGFloat(p.x), y: CGFloat(p.y))
            }
        }

        // أدوات مساعدة
        func center(_ a: [CGPoint]) -> CGPoint {
            guard !a.isEmpty else { return .zero }
            let sx = a.reduce(0) { $0 + $1.x }
            let sy = a.reduce(0) { $0 + $1.y }
            return CGPoint(x: sx / CGFloat(a.count), y: sy / CGFloat(a.count))
        }
        func rangeX(_ a: [CGPoint]) -> CGFloat {
            guard let mn = a.map({$0.x}).min(), let mx = a.map({$0.x}).max() else { return 0 }
            return mx - mn
        }
        func rangeY(_ a: [CGPoint]) -> CGFloat {
            guard let mn = a.map({$0.y}).min(), let mx = a.map({$0.y}).max() else { return 0 }
            return mx - mn
        }
        func clamp(_ v: CGFloat, _ a: CGFloat, _ b: CGFloat) -> CGFloat { max(a, min(b, v)) }

        // نقاط أساسية
        let mouthOuter = pts(landmarks.outerLips)
        let mouthInner = pts(landmarks.innerLips)
        let leye = pts(landmarks.leftEye)
        let reye = pts(landmarks.rightEye)
        let lbrow = pts(landmarks.leftEyebrow)
        let rbrow = pts(landmarks.rightEyebrow)

        // لو ما توفرت معالم كافية نرجّع محايد منخفض الثقة
        if mouthOuter.isEmpty || (leye.isEmpty && reye.isEmpty) {
            return ("Neutral", 0.2)
        }

        // قياسات فم
        let mAll = !mouthInner.isEmpty ? mouthInner : mouthOuter
        let mWidth  = rangeX(mouthOuter)
        let mHeight = rangeY(mAll)
        let mouthCenter = center(mAll)

        // تقدير زوايا الفم (يسار/يمين) كأقصى X
        let leftCorner  = mouthOuter.min(by: {$0.x < $1.x}) ?? mouthCenter
        let rightCorner = mouthOuter.max(by: {$0.x < $1.x}) ?? mouthCenter

        // نقاط أعلى وأسفل الشفة لمؤشر الانحناء
        let topLipY = mouthOuter.map{$0.y}.max() ?? mouthCenter.y
        let bottomLipY = mouthOuter.map{$0.y}.min() ?? mouthCenter.y
        let cornersAvgY = (leftCorner.y + rightCorner.y) / 2.0
        // ملاحظة: نظام إحداثيات Vision داخل المعالم قد يختلف في اتجاه y،
        // لذلك نعتمد على الفروقات المطلقة ونطبّع بالأبعاد.
        let curvature = (cornersAvgY - (topLipY + bottomLipY)/2.0)

        // قياسات عين/حاجب لرفع الحاجب
        let leftEyeC  = center(leye)
        let rightEyeC = center(reye)
        let eyeC = leye.isEmpty ? rightEyeC : (reye.isEmpty ? leftEyeC : CGPoint(x:(leftEyeC.x+rightEyeC.x)/2, y:(leftEyeC.y+rightEyeC.y)/2))
        let browC = center(lbrow + rbrow)

        let browRaiseRaw = abs(browC.y - eyeC.y)
        let faceH = max(boundingBox.height, 0.001)
        let faceW = max(boundingBox.width, 0.001)

        // نسب مطبّعة بقياس الوجه
        let mouthOpen = clamp(mHeight / max(mWidth, 0.001), 0, 1)             // MAR
        let browRaise = clamp(browRaiseRaw / max(faceH, faceW), 0, 1)
        let smileCurve = clamp(abs(curvature) / max(faceH, faceW), 0, 1)

        // تحويل القياسات إلى "نِسب" لكل شعور
        // صُممت العتبات بالتجربة لتناسب معظم الحالات (يمكنك تعديلها لاحقاً).
        var sSurprise = 0.0 as CGFloat
        var sHappy    = 0.0 as CGFloat
        var sSad      = 0.0 as CGFloat

        // مفاجأة: فم مفتوح + حاجب مرفوع
        sSurprise = 0.65 * mouthOpen + 0.35 * browRaise

        // سعادة: انحناء زوايا الفم + اتساع أفقي نسبي
        let mouthWide = clamp(mWidth / max(faceW, 0.001), 0, 1)
        sHappy = 0.6 * smileCurve + 0.4 * mouthWide

        // حزن: فم غير مفتوح + انحناء للأسفل (نقيسه بعكس اتساع الشفة وفرق المركز/الزوايا)
        let downTurn = clamp(( ( (topLipY + bottomLipY)/2.0 ) - cornersAvgY ).magnitude / max(faceH, faceW), 0, 1)
        sSad = 0.7 * downTurn + 0.3 * (1 - mouthOpen)

        // تطبيع النتائج إلى [0..1]
        func squash(_ x: CGFloat, t: CGFloat) -> CGFloat {
            // خريطة خطية مع عتبة بدء t
            return clamp((x - t) / max(0.001, (1 - t)), 0, 1)
        }

        let h = squash(sHappy,    t: 0.20)
        let z = squash(sSurprise, t: 0.25)
        let d = squash(sSad,      t: 0.22)

        // القرار + الثقة
        let scores: [(String, CGFloat)] = [("Happy", h), ("Surprised", z), ("Sad", d)]
        let best = scores.max(by: { $0.1 < $1.1 })!

        // إذا ولا واحد قوي، نرجّع محايد
        if best.1 < 0.45 {
            return ("Neutral", clamp(1 - (0.45 - best.1), 0.15, 0.55))
        } else {
            return (best.0, best.1)
        }
    }
}
