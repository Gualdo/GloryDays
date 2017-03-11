//
//  ViewController.swift
//  GloryDays
//
//  Created by Eduardo De La Cruz on 7/3/17.
//  Copyright © 2017 Eduardo De La Cruz. All rights reserved.
//

import UIKit
import AVFoundation // Para permisos de uso del microfono
import Photos // Para permisos de uso de fotos del usuario
import Speech // Para transcripcion de texto oral a escrito

class ViewController: UIViewController
{
    @IBOutlet weak var infoLabel: UILabel!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func askForPermissions(_ sender: UIButton)
    {
        self.askForPhotosPermissions()
    }
    
    func askForPhotosPermissions() // Pise los permisos al usuario para el uso de sus fotos
    {
        PHPhotoLibrary.requestAuthorization
            { [unowned self] (authStatus) in
                
                DispatchQueue.main.async // Se manada al hilo principal de ejecucion usando el main dejando de ser asincrona
                {
                    if authStatus == .authorized
                    {
                        self.askForRecordPermissions()
                    }
                    else
                    {
                        self.infoLabel.text = "Nos has denegado el permiso de fotos, por favor activalo en los ajustes de tu dispositivo para continuar"
                    }
                }
            }
    }
    
    func askForRecordPermissions() // Pide permisos para usar el microfono
    {
        AVAudioSession.sharedInstance().requestRecordPermission
            { [unowned self] (allowed) in
                DispatchQueue.main.async
                {
                    if allowed
                    {
                        self.askForTranscriptionPermissions()
                    }
                    else
                    {
                        self.infoLabel.text = "Nos has denegado el permiso de grabacion de audio, por favor activalo en los ajustes de tu dispositivo para continuar"
                    }
                }
            }
    }
    
    func askForTranscriptionPermissions() // Pide permisos para transcripcion de texto
    {
        SFSpeechRecognizer.requestAuthorization
            { [unowned self] (authStatus) in
                DispatchQueue.main.async
                {
                    if authStatus == .authorized
                    {
                        self.authorizationCompleted()
                    }
                    else
                    {
                        self.infoLabel.text = "Nos has denegado el permiso de transcripcion de texto, por favor activalo en los ajustes de tu dispositivo para continuar"
                    }
                }
            }
    }
    
    func authorizationCompleted() // Termina el proceso de permisologia
    {
        dismiss(animated: true, completion: nil)
    }
}
