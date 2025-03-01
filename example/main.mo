import Uploader "../src/uploader";
import Map "mo:map/Map";
import { nhash } "mo:map/Map";
import Debug "mo:base/Debug";
import Types "../src/types";

actor {
    type Uploader = Uploader.Uploader;
    type UploadResponse = Types.UploadResponse;
    type Asset = Types.AssetSave;
    type Result<T, U> = { #Ok : T; #Err : U };
    stable var assetId = 0;

    stable let files = Map.new<Nat, Asset>();

    ///////////////////////////////// Upload ///////////////////////////////////////////

    let uploader = Uploader.Uploader();

    public shared ({ caller }) func uploadRequest(fileName : Text, total_length : Nat) : async UploadResponse {
        uploader.uploadRequest(fileName, total_length, caller);
    };

    public shared ({ caller }) func addChunck(fileId : Nat, chunk : Blob, index : Nat) : async Result<(), Text> {
        Debug.print(debug_show(index));
        uploader.addChunk(fileId, chunk, index, caller);
    };

    public func commitLoad(fileId : Nat) : async Result<Nat, Text> {
        let response = uploader.commitLoad(fileId);
        switch response {
            case (#Ok(asset)) {
                ignore Map.put(files, nhash, assetId, asset);
                assetId += 1;
                Debug.print("File id: " # debug_show(assetId - 1));
                #Ok(assetId - 1);
            };
            case (#Err(e)) { #Err(e) };
        };
    };

    ////////////////////////// Download ///////////////////////////////

    public query func startDownload(fileId : Nat) : async Result<Asset, Text> {
        let file = Map.get(files, nhash, fileId);
        switch file {
            case null { #Err("File Not Found") };
            case (?file) { #Ok({ file with content_chunks = [] }) };
        };
    };

    public query func getChunck(fileId : Nat, chunckIndex : Nat) : async Result<Blob, Text> {
        let file = Map.get(files, nhash, fileId);
        switch file {
            case null { #Err("File Not Found") };
            case (?file) {
                #Ok(file.content_chunks[chunckIndex]);
            };
        };
    };
    ////////////////////////////////////////////////////////////////////
};
