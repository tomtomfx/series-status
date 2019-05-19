<?php
class Database{
 
    // specify your own database credentials
    private $dbfile = "../../series/series.db";
    private $db = null;
 
    public function dbinit() {
		if ($this->db == null) 
			$this->db = new SQLite3($this->dbfile);
	}
	
	public function dbclose() {
		$this->db->close();
		$this->db = null;	
	}

    // get the database connection
    public function getDB(){
        return $this->db;
    }
}
?>