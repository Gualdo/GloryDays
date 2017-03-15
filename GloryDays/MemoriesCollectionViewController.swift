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

class MemoriesCollectionViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    //MARK: - Global Variables
    
    var memories : [URL] = []
    
    //MARK: - Overrides
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.loadMemories()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addImagePressed)) // Crear un boton por codigo en el navigation bar para agregar items llamando al metodo addImagePressed que creamos mas abajo

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

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
    
        return cell
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
