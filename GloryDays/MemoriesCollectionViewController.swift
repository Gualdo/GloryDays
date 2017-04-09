//
//  MemoriesCollectionViewController.swift
//  GloryDays
//
//  Created by Eduardo De La Cruz on 7/3/17.
//  Copyright © 2017 Eduardo De La Cruz. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Speech

private let reuseIdentifier = "cell"

class MemoriesCollectionViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVAudioRecorderDelegate
{
    //MARK: - Global Variables
    
    var memories : [URL] = []
    var currentMemory : URL!
    var audioRecorder : AVAudioRecorder?
    var recordingURL : URL!
    var audioPlayer : AVAudioPlayer?
    
    //MARK: - Overrides
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.recordingURL = getDocumentoDirectory().appendingPathComponent("memory-recording.m4a")
        
        self.loadMemories()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addImagePressed)) // Crear un boton por codigo en el navigation bar para agregar items llamando al metodo addImagePressed que creamos mas abajo

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        //self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) // Las transiciones entre view controller no se deben hacer en ViewDidLoad sino aqui
    {
        super.viewDidAppear(animated)
        
        self.checkForGrantedPermissions()
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Defined Methods
    
    func checkForGrantedPermissions()
    {
        let photosAuth : Bool = PHPhotoLibrary.authorizationStatus() == .authorized
        let recordingAuth : Bool = AVAudioSession.sharedInstance().recordPermission() == .granted
        let transcriptionAuth : Bool = SFSpeechRecognizer.authorizationStatus() == .authorized
        
        let authorized = photosAuth && recordingAuth && transcriptionAuth // Si tengo autorizacion para los 3 el valor sera true
        
        if !authorized
        {
            if let vc = storyboard?.instantiateViewController(withIdentifier: "ShowTerms")
            {
                navigationController?.present(vc , animated: true, completion: nil)
            }
        }
    }
    
    func loadMemories() // Carga las memorias desde disco en donde esten guardadas
    {
        self.memories.removeAll() // Se vacia el array para asegurar que no duplicamos nada
        
        guard let files = try? FileManager.default.contentsOfDirectory(at: getDocumentoDirectory(), includingPropertiesForKeys: nil, options: []) // Devuelve el conjunto de archivos que se encuentren en la funcion de abajo (getDocumentsDirectory) sin opciones por eso el [], se utiliza el guard ya que es lo mismo que el do try catch puesto que el la funcion getDocumentosDirectory puede que no devuelva nada o de error y puede petar es mejor usar el guard ya que si se pasa con exito podemos seguir usando abajo la variable files que contiene los archivos que se encontrar a diferencia del try cath que usa un for u no se puede usar mas la variable fuera del for
            else
            {
                return // Se devuelve vacio para terminar la ejecucion en caso de un error
            }
        
        for file in files
        {
            let fileName = file.lastPathComponent // Da el nombre del archivo
            
            if fileName.hasSuffix(".thumb") // Hace la revision de que el archivo sea un .thumb que son las miniaturas
            {
                let noExtension = fileName.replacingOccurrences(of: ".thumb", with: "") // Elimina la extencion del nombre del archivo y solo se queda con el nombre
                
                let memoryPath = getDocumentoDirectory().appendingPathComponent(noExtension)
                
                memories.append(memoryPath) // Estoy agregando en el arreglo de memories un nombre sin extencion para luego colocandole la extencion deseada puedo usar la foto, el thumb, el texto o la grabacion
            }
        }
        
        collectionView?.reloadSections(IndexSet(integer : 1)) // Recarga la seccion numero 1 y no el 0 ya que la barra de busqueda de la app esta en la 0 las imagenees empiezan en el 1
    }
    
    func getDocumentoDirectory() -> URL
    {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask) // documentDirectory donde se guardan en gener los dumentos de las app y userDomainMask es donde se guardan los archivos del usuario
        let documentsDirectory = paths[0] // Nos quedamos con el primer path para guardar y cargar las fotos
        
        return documentsDirectory
    }
    
    func addImagePressed()
    {
        let vc = UIImagePickerController() // Se crea una llamada al ViewController de picker
        
        vc.modalPresentationStyle = .formSheet // Se seleccion el estilo de presentacion de este view controller con el estilo formSheet
        
        vc.delegate = self // Se le dice al sistema que nosotros mismos somos el delegado ya que nuestra clase se encarga de gestionar la seleccion o cancelacion de imagenes
        
        navigationController?.present(vc, animated: true, completion: nil) // Se presenta el viewcontroller y se usa el navigationController ya que estamos en un navigation controller
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) // Importa nuevas fotos
    {
        if let theImage = info[UIImagePickerControllerOriginalImage] as? UIImage
        {
            addNewMemory(image: theImage) // Se llama al metodo para agregar una nueva imagen
            
            self.loadMemories() // refresca la colection view con los datos nuevos
            
            dismiss(animated: true, completion: nil)
        }
    }
    
    func addNewMemory(image : UIImage) // Guarda imagenes en disco en forma de imagenes y de miniaturas para mejorar el scroll
    {
        let memoryName = "memory-\(Date().timeIntervalSince1970)" // 1970 Traduce el tiempo desde esa epoca hasta el momento en segundos para que no exista ningun nombre igual
        
        let imageName = "\(memoryName).jpg"
        let thumbName = "\(memoryName).thumb"
        
        do
        {
            let imagePath = getDocumentoDirectory().appendingPathComponent(imageName) // En la carpeta principal donde estan los recursos de nuestra app crear una carpeta para la imagen en jpg
            
            if let jpegData = UIImageJPEGRepresentation(image, 80) // Crea una imagen en mapa de bits comprimiendo en este caso al 80%
            {
                try jpegData.write(to: imagePath, options: [.atomicWrite]) // Atomic hace que se escriba todo junto no en varias partes del disco
            }
            
            if let thumbnail = resizeImage(image: image, to: 200) // Se llama al codigo de miniaturizacion para luego hacer el proceso de guardado igual que arriba
            {
                let thumbPath = getDocumentoDirectory().appendingPathComponent(thumbName)
                
                if let jpegData = UIImageJPEGRepresentation(thumbnail, 80)
                {
                    try jpegData.write(to: thumbPath, options: [.atomicWrite])
                }
            }
        }
        catch
        {
            print("Ha fallado la escritura en disco")
        }
    }
    
    func resizeImage(image : UIImage , to width : CGFloat) -> UIImage? // Metodo para escalar la imagen para el thumb
    {
        let scaleFactor = width/image.size.width // Se consigue el factor de escalado teniendo en cuenta que ya se sabe el alcho que se quiere
        
        let height = image.size.height * scaleFactor // Se busca la altura de la imagen resultante usando el mismo factor de escalado para mantener la estetica
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width : width , height : height) , false, 0) // Redimenciona la imagen
        
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height)) // Redibuja la imagen dentro de este rectangulo que creamos
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext() // Del contexto en el que estamos trabajando obtiene la nueva imagen y la crea
        
        UIGraphicsEndImageContext() // Finaliza la edicion de la imagen
        
        return newImage
    }
    
    func imageURL(for memory : URL) -> URL // Consige la url de la imagen de la memoria
    {
        return memory.appendingPathExtension("jpg")
    }
    
    func thumbnailURL(for memory : URL) -> URL // Consige la url del thumbnail de la memoria
    {
        return memory.appendingPathExtension("thumb")
    }
    
    func audioURL(for memory : URL) -> URL // Consige la url del audio de la memoria
    {
        return memory.appendingPathExtension("m4a")
    }
    
    func transcriptionURL(for memory : URL) -> URL // Consige la url de la transcripcion del audio de la memoria
    {
        return memory.appendingPathExtension("txt")
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int
    {
        // #warning Incomplete implementation, return the number of sections
        return 2 // Genera las dos secciones que tiene la app
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        // #warning Incomplete implementation, return the number of items
        
        if section == 0
        {
            return 0 // Ya que en la seccion inicial no hay elementos no hay que mostrar una celda solo esta la barra de busqueda
        }
        else
        {
            return self.memories.count // Muestra la cantidad de elementos que contenga el Array memories
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MemoryCell // Hace que las celdas que ya pasamos sean reutilizadas
        
        let memory = self.memories[indexPath.row] // Recuperamos el recuedno en particular por la fila seleccionada usando el row
        
        let memoryName = self.thumbnailURL(for: memory).path // Obtiene el nombre de la memoria
        
        let image = UIImage(contentsOfFile: memoryName)
        
        cell.imageView.image = image
        
        if cell.gestureRecognizers == nil // Se le da la opcion de presionado largo a la celda
        {
            let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.memoryLogPressed(sender:)))
            recognizer.minimumPressDuration = 0.3
            cell.addGestureRecognizer(recognizer)
            
            cell.layer.borderColor = UIColor.white.cgColor //Con estas 3 lineas de codigo se le da formato a la estica de la celda
            cell.layer.borderWidth = 4
            cell.layer.cornerRadius = 10
        }
    
        return cell
    }
    
    func memoryLogPressed(sender : UILongPressGestureRecognizer) // Detecta pulsaciones prolongadas
    {
        if sender.state == .began
        {
            let cell = sender.view as! MemoryCell // Trae cual es la celda (memoria) que fue presionada de forma prolongada
            
            if let index = collectionView?.indexPath(for: cell) // Se obtiene el index de la celda en cuestion
            {
                self.currentMemory = self.memories[index.row]
                
                self.startRecordingMemory() // Se empieza el proceso de grabado para esta celda
            }
        }
        
        if sender.state == .ended
        {
            self.finishRecordingMemory(success: true) // Se finaliza el proceso de grabado de esta celda
        }
    }
    
    func startRecordingMemory()
    {
        audioPlayer?.stop() // En caso de que al momento de grabar se esta reproduciendo un sonido este lo detiene
        
        collectionView?.backgroundColor = UIColor(red: 0.6, green: 0.0, blue: 0.0, alpha: 1.0) // Se pone el fondo de color rojo para darle feedback al usuario de que se esta grabando
        
        let recordingSession = AVAudioSession.sharedInstance() // Se crea una instancia compartida de grabacion de audio
        
        do
        {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker) // Se usa el Play and Record ya que se quiere no solo guardar sino tambien escuchar lo que el usuario grabo con la misma sesion
            try recordingSession.setActive(true)
            
            let recordingSettings = [ AVFormatIDKey : Int(kAudioFormatMPEG4AAC), // Tipo de archivo de sonido que se va a grabar
                                      AVSampleRateKey : 44100, // Calidad del sonido que se va a guardar
                                      AVNumberOfChannelsKey : 2, // Canales de grabacion
                                      AVEncoderAudioQualityKey : AVAudioQuality.high.rawValue // Calidad del codificador todas las configuraciones tiene que estar en INT por eso el .rawValue
                                    ]
            
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: recordingSettings)
            audioRecorder?.delegate = self //Marca la clase como delegado que se encarga de empezar y terminar la grabacion
            audioRecorder?.record() //Comienza a grabar
        }
        catch let error
        {
            print(error)
            finishRecordingMemory(success: false)
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) // Revisa si se logro la grabacion de forma correcta
    {
        if !flag
        {
            finishRecordingMemory(success: false)
        }
    }
    
    func finishRecordingMemory(success : Bool)
    {
        collectionView?.backgroundColor = UIColor(red: 97.0/255.0, green: 86.0/255.0, blue: 110.0/255.0, alpha: 1.0)
        audioRecorder?.stop()
        
        if success
        {
            do
            {
                let memoryAudioURL = self.currentMemory.appendingPathExtension("m4a")
                let fileManager = FileManager.default
                
                if fileManager.fileExists(atPath: memoryAudioURL.path)
                {
                    try fileManager.removeItem(at: memoryAudioURL)
                }
                
                try fileManager.moveItem(at: recordingURL, to: memoryAudioURL)
                self.transcribeAudioToText(memory: self.currentMemory) //Transcribe el audio en la memoria que esta seleccionada
            }
            catch let error
            {
                print("Ha habido un error \(error)")
            }
        }
    }
    
    func transcribeAudioToText(memory : URL)
    {
        let audio = audioURL(for: memory)
        let transcription = transcriptionURL(for: memory)
        
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: audio)
        
        recognizer?.recognitionTask(with: request, resultHandler:
            { [unowned self] (result, error) in
            guard let result = result else
                                      {
                                        print("Ha habido el siguiente error: \(String(describing: error))")
                                        return
                                      }
                
                if result.isFinal
                {
                    let text = result.bestTranscription.formattedString //Guarda la mejor traduccion posible aunque el array tra varias que se pueden usar
                    
                    do
                    {
                        try text.write(to: transcription, atomically: true, encoding: String.Encoding.utf8)
                    }
                    catch
                    {
                        print("Ha habido un error al guardar la transcripcion")
                    }
                }
            })
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView // Configura la barra de busqueda que tenemos arriba
    {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath)
        
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize
    {
        if section == 0
        {
            return CGSize(width: 0, height: 50)
        }
        else
        {
            return CGSize.zero
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) //Maneja las pulsaciones cortas de una memory
    {
        let memory = self.memories[indexPath.row]
        let fileManager = FileManager.default
        
        do
        {
            let audioName = audioURL(for: memory)
            let transcriptionName = transcriptionURL(for: memory)
            
            if fileManager.fileExists(atPath: audioName.path)
            {
                self.audioPlayer = try AVAudioPlayer(contentsOf: audioName)
                self.audioPlayer?.play()
            }
            
            if fileManager.fileExists(atPath: transcriptionName.path)
            {
                let contents = try String(contentsOf: transcriptionName)
                print(contents)
            }
        }
        catch
        {
            print("Error al cargar el medio a reproducir")
        }
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */
}
