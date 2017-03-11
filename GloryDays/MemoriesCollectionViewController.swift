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

private let reuseIdentifier = "Cell"

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
    
    func loadMemories()
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
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
    {
        if let theImage = info[UIImagePickerControllerOriginalImage] as? UIImage
        {
            addNewMemory(image: theImage) // Se llama al metodo para agregar una nueva imagen
            
            self.loadMemories() // refresca la colection view con los datos nuevos
        }
    }
    
    func addNewMemory(image : UIImage)
    {
        
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
        return 0
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        // #warning Incomplete implementation, return the number of items
        return 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
    
        // Configure the cell
    
        return cell
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
