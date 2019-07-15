<?php
class Tablets{
 
    // database connection and table name
    private $db;
    private $table_name = "Tablets";
 
    // constructor with $db as database connection
    public function __construct($dbConn){
        $this->db = $dbConn;
    }

    public function updateTabletLastConnection($id)
    {
        date_default_timezone_set('CET');
        $date = date("d-m-Y H:i");
        $q = "UPDATE Tablets SET lastConnection = \"$date\" WHERE Id=\"".$id."\"";
		$queryRes = $this->db->query($q);
		return $queryRes;
    }
}