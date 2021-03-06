//
//  ViewController.swift
//  Audio
//
//  Created by TH on 9/6/17.
//  Copyright © 2017 Essential Studio. All rights reserved.
//

import UIKit
import SDWebImage
import UICheckbox_Swift
import GoogleMobileAds

class ListAudioViewController: BaseAudioViewController {
    
    @IBOutlet weak var cbMale: UICheckbox!
    @IBOutlet weak var cbFemale: UICheckbox!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var viewControler: UIView!
    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var imgBackground: UIImageView!
    @IBOutlet weak var imgLoading: UIImageView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var labelDuration: UILabel!
    @IBOutlet weak var labelCurrent: UILabel!
    
    let viewModel = ListAudioViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.backgroundView = nil
        viewModel.viewDelegate = self
        configView()
        configCheckBox()
        NotificationCenter.default.addObserver(self, selector:#selector(self.appEnterFromBackground), name: Notification.Name.UIApplicationWillEnterForeground, object: nil)
        reloadUIState()
    }
    
    @IBAction func switchPlayAndPause(_ sender: Any) {
        viewModel.switchPlayAndPause()
    }
    
    @IBAction func next(_ sender: Any) {
        viewModel.next()
    }
    
    @IBAction func previous(_ sender: Any) {
        viewModel.previous()
    }
    
    @IBAction func openDetail(_ sender: Any) {
        viewModel.continuePlayingOrStartOver()
        openAudioPlayerScreenIfNeeded()
    }
    

    @IBAction func seekTo(_ sender: UISlider) {
        viewModel.seekTo(value: sender.value)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.viewWillAppear()
        //reloadUIState()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        viewModel.viewWillDisappear()
    }
    
    func appEnterFromBackground()  {
        reloadUIState()
    }
    
    func reloadUIState()  {
        tableView.reloadData()
        if(viewModel.getCurrentAudioItem() != nil){
            if(viewControler.isHidden){
                viewControler.isHidden = false
                self.view.getContraint(withIdentifier: "tableViewBottomContraint")?.constant = viewControler.frame.size.height
            }
            if(viewModel.isPlayingAudio()){
                btnPlay.setImage(R.image.pause(), for: .normal)
            }else{
                btnPlay.setImage(R.image.play(), for: .normal)
            }
        }else{
            if(!viewControler.isHidden){
                viewControler.isHidden = true
                self.view.getContraint(withIdentifier: "tableViewBottomContraint")?.constant = 0
            }
        }
        let isLoaded = viewModel.getCurrentPlayingTime() > 0
        if(isLoaded){
            setPlayingState(isLoaded: isLoaded, isPlaying: viewModel.isPlayingAudio())
        }else{
            setPlayingState(isLoaded: isLoaded, isPlaying: viewModel.getCurrentPlayingTime() > 0)
        }
    }
    
    func configView()  {
        if !Constants.BuildConfig.DEBUG {
            imgBackground.image = R.image.background()
        }
    }
    
    func configCheckBox()  {
        cbMale.onSelectStateChanged = { (checkbox, selected) in
            self.viewModel.didChangeSpeakerFilter(male: self.cbMale.isSelected, female: self.cbFemale.isSelected)
        }
        cbFemale.onSelectStateChanged = { (checkbox, selected) in
            self.viewModel.didChangeSpeakerFilter(male: self.cbMale.isSelected, female: self.cbFemale.isSelected)
        }
    }
    
    func openAudioPlayerScreenIfNeeded() {
        if Constants.Application.OPEN_SLIDE_SHOW {
            performSegue(withIdentifier: "showAudioPlayerScreen", sender: self)
        }
    }
    
    func showUnlockAudioPopup(index: Int, item: AudioModel)  {
        let alert = UIAlertController(title: "Mở khoá", message: "Xem quảng cáo để mở khoá audio này", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Huỷ", style: UIAlertActionStyle.default, handler: nil))
        alert.addAction(UIAlertAction(title: "Đồng ý", style: UIAlertActionStyle.default, handler: { action in
            super.showAds(lockedAudio: item)
        }))
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func didUnlockAudio(unlockAudio: AudioModel) {
        self.viewModel.unlockedNewAudio(unlockedItem: unlockAudio)
    }
    
    func setPlayingState(isLoaded: Bool, isPlaying: Bool)  {
        if viewModel.getCurrentAudioItem() != nil{
            if !isLoaded && !isPlaying{
                imgLoading.rotate360Degrees()
                imgLoading.isHidden = false
                btnPlay.isHidden = true
            }else{
                labelDuration.text = viewModel.getDurationText()
                slider.value = viewModel.getCurrentPlayingTime()
                slider.maximumValue = viewModel.getDurationNumber()!
                
                imgLoading.layer.removeAllAnimations()
                imgLoading.isHidden = true
                btnPlay.isHidden = false
                if isPlaying{
                    btnPlay.setImage(R.image.pause(), for: .normal)
                }
                else{
                     btnPlay.setImage(R.image.play(), for: .normal)
                }
            }
        }
    }
    
    deinit {
        viewModel.destroy()
        NotificationCenter.default.removeObserver(self)
    }
}

class AdsViewCell: UITableViewCell {
    
    @IBOutlet weak var adsBanner: GADBannerView!
    
    func run(rootViewController : UIViewController)  {
        adsBanner.cornerRadiusRatio = 0.03
        AdsManager.instance.showBannerAds(adsBanner: adsBanner, viewController: rootViewController)
    }
}

class AudioTableViewCell : UITableViewCell{
    @IBOutlet weak var imgAudio: UIImageView!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var imgSpeaker: UIImageView!
    @IBOutlet weak var imgPlaying: UIImageView!
    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var labelSpeaker: UILabel!
    @IBOutlet weak var imgLock: UIImageView!
    
    func bindData(item: AudioModel)  {
        self.backgroundColor = UIColor.clear
        viewContainer.cornerRadiusRatio = 0.03
        labelName.text = item.name
        imgAudio.sd_setImage(with: URL(string: item.image!)!, placeholderImage: R.image.placeholder()!, fadeIn: true)
  
        imgAudio.cornerRadiusRatio = 0.08
        if item == AudioManager.instance.getCurrentAudioItem(){
            imgPlaying.isHidden = false
            imgPlaying.cornerRadiusRatio = 0.08
        }else{
            imgPlaying.isHidden = true
        }
        if(item.speaker==0){
            if !Constants.BuildConfig.DEBUG{
                imgSpeaker.image = R.image.girl()
            }
            labelSpeaker.text = "Giọng nữ"
        }else{
            if !Constants.BuildConfig.DEBUG{
                imgSpeaker.image = R.image.boy()
            }
            labelSpeaker.text = "Giọng nam"
        }
        imgLock.isHidden = item.hasUnlocked()
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if(highlighted){
            viewContainer.alpha = 0.8
        }else{
            viewContainer.alpha = 1
        }
    }
    
}

extension ListAudioViewController : UITableViewDataSource,UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return viewModel.itemsCount
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let item = viewModel.itemAtIndex(index: indexPath.row)!
        if !item.isAdsItem {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! AudioTableViewCell
            cell.bindData(item: item)
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "ads_cell", for: indexPath) as! AdsViewCell
        cell.run(rootViewController: self)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.didSelectItemAtIndex(index: indexPath.row)
    }
}

extension ListAudioViewController : ListAudioDelegate {
    func itemsDidChange() {
        tableView.reloadData()
    }
    
    func didSelectItem(item: AudioModel) {
        if !item.isAdsItem{
            reloadUIState()
            openAudioPlayerScreenIfNeeded()
        }
    }
    
    func audioPreparing() {
        setPlayingState(isLoaded: false, isPlaying: false)
    }
    
    func audioChangeStatePlaying(){
        setPlayingState(isLoaded: true,isPlaying: true)
        btnPlay.setImage(R.image.pause(), for: .normal)
    }
    
    func audioChangeStatePause(){
        btnPlay.setImage(R.image.play(), for: .normal)
    }
    
    func audioChangeStateNext(){
        tableView.reloadData()
    }
    
    func audioChangeStatePrevious(){
        tableView.reloadData()
    }
    
    func askingToUnlockAudio(index: Int, item: AudioModel) {
        showUnlockAudioPopup(index: index, item: item)
    }
    
    func audioInteralUpdate(value: Float){
        slider.isUserInteractionEnabled = true
        self.slider.value = value
        if value != 0 {
            if slider.maximumValue == 0 {
                slider.maximumValue = viewModel.getDurationNumber()!
            }
            if labelDuration.text == "00:00"{
                labelDuration.text = viewModel.getDurationText()
            }
            labelCurrent.text = viewModel.getCurrentTimeText()
        }else{
            slider.isUserInteractionEnabled = false
            labelDuration.text = "00:00"
            labelCurrent.text = "00:00"
        }
    }
}

