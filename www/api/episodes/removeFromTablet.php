<?php
// required headers
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
 
// include database and object files
include_once '../config/database.php';
include_once '../objects/episodes.php';

// get posted data
$data = json_decode(file_get_contents("php://input"));
if(!empty($data->Id))
{
    $episodeId = $data->Id;

    // instantiate database and product object
    $database = new Database();
    $database->dbinit();
    $db = $database->getDB();
    if ($db == null)
    {
        // set response code - 404 Not found
        http_response_code(404);
        echo json_encode(array("message" => "Cannot open database."));
    }
    else
    {
        // initialize object
        $episodes = new Episodes($db);
        $status = $episodes->removeEpisodeFromTablet($episodeId);

        if ($status != false)
        {
            // set response code - 200 OK
            http_response_code(200); 
            echo json_encode($status);
        }
        else
        {
            // set response code - 404 Not found
            http_response_code(404);
            echo json_encode(array("message" => "Cannot update episode with id: ".$episodeId));
        }
        
        // Close database connection
        $database->dbclose();
    }
}
else
{
    // set response code - 404 Not found
    http_response_code(404);
    echo json_encode(array("message" => "Episode ID need to be specified"));
}
?>