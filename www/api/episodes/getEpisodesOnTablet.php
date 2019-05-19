<?php
// required headers
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
 
// include database and object files
include_once '../config/database.php';
include_once '../objects/episodes.php';

// get posted data
$data = json_decode(file_get_contents("php://input"));
if(!empty($data->tablet))
{
    $tablet = $data->tablet;

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
        $episodesList = $episodes->getEpisodesOnTablet($tablet);

        if ($episodesList != 0)
        {
            // set response code - 200 OK
            http_response_code(200); 
            // show products data in json format
            echo json_encode($episodesList);
        }
        else
        {
            // set response code - 404 Not found
            http_response_code(404);
            echo json_encode(array("message" => "No episode found."));
        }
        
        // Close database connection
        $database->dbclose();
    }
}
else
{
    // set response code - 404 Not found
    http_response_code(404);
    echo json_encode(array("message" => "Tablet ID need to be specified"));
}
?>