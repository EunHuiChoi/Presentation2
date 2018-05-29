//
//  ViewController.swift
//  BasicAudioPlayer
//
//  Created by SWUCOMPUTER on 2018. 5. 29..
//  Copyright © 2018년 SWUCOMPUTER. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {

    @IBOutlet var pvProgressPlay: UIProgressView!
    @IBOutlet var currentTime: UILabel!
    @IBOutlet var endTime: UILabel!
    @IBOutlet var buttonPause: UIButton!
    @IBOutlet var buttonPlay: UIButton!
    @IBOutlet var buttonStop: UIButton!
    @IBOutlet var sliderVol: UISlider!
    @IBOutlet var buttonRecord: UIButton!
    @IBOutlet var recordTime: UILabel!
    
    var audioPlayer : AVAudioPlayer!
    var audioFile : URL!
    let MAX_VOLUME : Float = 10.0
    var progressTimer : Timer!
    var audioRecorder : AVAudioRecorder!
    var isRecodeMode = false
    
    let timePlaySelector: Selector = #selector(ViewController.updatePlayTime)
    let timeRecordSelector: Selector = #selector(ViewController.updateRecordTime)
    
    @objc func updatePlayTime() {
        currentTime.text = convertNSTimeInterval2String(audioPlayer.currentTime)
        pvProgressPlay.progress = Float(audioPlayer.currentTime/audioPlayer.duration)
    }
    
    @objc func updateRecordTime() {
        recordTime.text = convertNSTimeInterval2String(audioRecorder.currentTime)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectAudioFile()
        if !isRecodeMode {
            initPlay()
            buttonRecord.isEnabled = false
            recordTime.isEnabled = false
        }
        else {
            initRecord()
        }
    }
    
    func initPlay() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFile)
        } catch let error as NSError {
            print("Error-initPlay : \(error)")
        }
        sliderVol.maximumValue = MAX_VOLUME
        sliderVol.value = 1.0
        pvProgressPlay.progress = 0
        
        //audioPlayer.delegate = self
        //audioPlayer.prepareToPlay()
        //audioPlayer.volume = sliderVol.value
        //endTime.text = convertNSTimeInterval2String(audioPlayer.duration)
        //currentTime.text = convertNSTimeInterval2String(0)
        
        setPlayButtons(true, pause: false, stop: false)
    }
    
    func initRecord() {
        let recordSettings = [AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless as UInt32),
                              AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
                              AVEncoderBitRateKey: 320000,
                              AVNumberOfChannelsKey: 2,
        AVSampleRateKey: 44100.0] as [String : Any]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFile, settings: recordSettings)
        } catch let error as NSError {
            print("Error-initRecord : \(error)")
        }
        audioRecorder.delegate = self
        audioRecorder.isMeteringEnabled = true
        audioRecorder.prepareToRecord()
        
        sliderVol.value = 1.0
        audioPlayer.volume = sliderVol.value
        endTime.text = convertNSTimeInterval2String(0)
        currentTime.text = convertNSTimeInterval2String(0)
        setPlayButtons(false, pause: false, stop: false)
        
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch let error as NSError {
            print("Error-setCategory: \(error)")
        }
        do {
            try session.setActive(true)
        } catch let error as NSError {
            print("Error-setActive: \(error)")
        }
    }
    
    func setPlayButtons(_ play: Bool, pause: Bool, stop: Bool) {
        buttonPlay.isEnabled = play
        buttonPause.isEnabled = pause
        buttonStop.isEnabled = stop
    }
    
    func convertNSTimeInterval2String(_ time: TimeInterval) -> String {
        let min = Int(time/60)
        let sec = Int(time.truncatingRemainder(dividingBy: 60))
        let stringTime = String(format: "%02d:%02d", min, sec)
        return stringTime
    }
    
    @IBAction func buttonPlayAudio(_ sender: UIButton) {
        audioPlayer.play()
        setPlayButtons(false, pause: true, stop: true)
        progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timePlaySelector, userInfo: nil, repeats: true)
    }
    
    @IBAction func buttonPauseAudio(_ sender: UIButton) {
        audioPlayer.pause()
        setPlayButtons(true, pause: false, stop: false)
    }
    
    @IBAction func buttonStopAudio(_ sender: UIButton) {
        audioPlayer.stop()
        audioPlayer.currentTime = 0
        currentTime.text = convertNSTimeInterval2String(0)
        setPlayButtons(true, pause: false, stop: false)
        progressTimer.invalidate()
    }
    
    @IBAction func chagneVolum(_ sender: UISlider) {
        audioPlayer.volume = sliderVol.value
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        progressTimer.invalidate()
        setPlayButtons(true, pause: false, stop: false)
    }
    
    @IBAction func recordingMode(_ sender: UISwitch) {
        if sender.isOn {
            audioPlayer.stop()
            audioPlayer.currentTime = 0
            recordTime!.text = convertNSTimeInterval2String(0)
            isRecodeMode = true
            buttonRecord.isEnabled = true
            recordTime.isEnabled = true
        }
        else {
            isRecodeMode = false
            buttonRecord.isEnabled = false
            recordTime.isEnabled = false
            recordTime.text = convertNSTimeInterval2String(0)
        }
        selectAudioFile()
        if !isRecodeMode {
            initPlay()
        }
        else {
            initRecord()
        }
    }
    
    @IBAction func buttonRecordStart(_ sender: UIButton) {
        if sender.titleLabel?.text == "Record" {
            audioRecorder.record()
            sender.setTitle("Stop", for: UIControlState())
            progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timeRecordSelector, userInfo: nil, repeats: true)
        }
        else {
            audioRecorder.stop()
            progressTimer.invalidate()
            sender.setTitle("Record", for: UIControlState())
            buttonPlay.isEnabled = true
            initPlay()
        }
    }
    
    func selectAudioFile() {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        audioFile = documentDirectory.appendingPathComponent("recordFile.m4a")
    }
}

