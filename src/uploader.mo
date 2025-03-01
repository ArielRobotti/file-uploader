// import Types "./types";
import {nhash } "mo:map/Map";
import Map "mo:map/Map";
import Prim "mo:⛔";
import Types "types";

module {
    type FileID = Types.FileID;
    type TempAsset = Types.TempAsset;
    type UploadResponse = Types.UploadResponse;
    type AssetSave = Types.AssetSave;
    type Chunk = Types.Chunk;
    type ChunkIndex = Nat;
    type Result<T,U> = {#Ok: T; #Err: U};
    
    public class Uploader() = {
        let filesUploading = Map.new<FileID, TempAsset>();
        let generateId = Prim.time;

        // From the frontend you must send the file name and its size in bytes extracted from the file object, 
        // and wait for the return object from which the chunk dump data will be extracted. This data is: dump file id, 
        // size in bytes that the chunks should have and number of chunks.
        public func uploadRequest(fileName: Text, fileSize: Nat, owner: Principal): UploadResponse {
            let chunkSize = 1_048_576;   // Size in Bytes of the Chunks. Example 1_048_576 -> 1MB
            let id = Prim.nat64ToNat(generateId()); // Timestamp in NanoSeg : Nat64
            let chunksQty = fileSize / chunkSize + (if (fileSize % chunkSize > 0) {1} else {0});
            
            let content_chunks = Prim.Array_init<Blob>(chunksQty, ""); //
            let newAsset = {
                owner;
                fileName;
                date = id; 
                content_chunks;
                chunks_qty = chunksQty;
                total_length = fileSize;
                certified = false;
            };
            ignore Map.put<FileID, TempAsset>(filesUploading, nhash, id, newAsset);
            {id; chunksQty; chunkSize };
        };
        
        public func addChunk(fileId: FileID, chunk: Chunk, index: ChunkIndex, owner: Principal ): Result<(),Text>{
            let file = Map.get(filesUploading, nhash, fileId);
            switch file {
                case null {#Err("Archivo de carga no encontrado")};
                case (?file) {
                    if (file.owner != owner) {
                        return #Err("Caller is not owner")
                    };
                    file.content_chunks[index] := chunk;
                    #Ok
                }
            }
        };

        func frezze<T>(arr: [var T]): [T]{  
            Prim.Array_tabulate<T>(arr.size(), func x = arr[x])
        };
        public func commitLoad(fileId: FileID): Result<AssetSave, Text>{
            let file = Map.get(filesUploading, nhash, fileId);
            switch file {
                case null { 
                    return #Err("No se encuentra el Id")
                };
                case (?file){
                    var size = 0;
                    for (ch in file.content_chunks.vals()){
                        size += ch.size();
                    };
                    if(size != file.total_length){
                        Map.delete(filesUploading, nhash, fileId);
                        return #Err("Tamaño incorrecto");
                    };
                    let content_chunks = frezze(file.content_chunks);
                    Map.delete(filesUploading, nhash, fileId);
                    #Ok( { file with content_chunks } )
                }
            };    
        };

    };

};
