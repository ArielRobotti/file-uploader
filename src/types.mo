module {
    public type AssetMetadata = {
        fileName : Text;
        total_length : Nat;
    };
    public type TempAsset = {
        owner: Principal;
        fileName : Text;
        date : Int;
        content_chunks : [var Blob];
        chunks_qty: Nat;
        total_length : Nat;
        certified : Bool;
    }; 
    public type AssetSave = {
        fileName : Text;
        date : Int;
        content_chunks : [Blob];
        chunks_qty: Nat;
        total_length : Nat;
        certified : Bool;
    };
    public type UploadResponse = {
        id: FileID;
        chunksQty: Nat;
        chunkSize: Nat;
    };
    /////////////////////////////
    public type Chunk = Blob;
    public type FileID = Nat;
}