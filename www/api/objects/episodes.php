<?php
class Episodes{
 
    // database connection and table name
    private $db;
    private $table_name = "unseenEpisodes";
 
    // constructor with $db as database connection
    public function __construct($dbConn){
        $this->db = $dbConn;
    }

    public function getEpisodesToSee()
    {
        $episodes;
        $q = "SELECT Id, Status, IdBetaseries, Archived FROM unseenEpisodes";
		$queryRes = $this->db->query($q);
			
		while ($episode = $queryRes->fetchArray())
		{
            if ($episode['Archived'] == "TRUE") continue;
            $data = [
                "Status" => $episode['Status'],
                "IdBetaseries" => $episode['IdBetaseries']
            ];
			$episodes[$episode['Id']] = $data;
        }
        if (isset($episodes)){return $episodes;}
        else{return 0;}
    }

    public function getEpisodesToDownload($tabletId)
    {
        $episodes;
        $q = "SELECT Id, Location FROM unseenEpisodes WHERE Tablet=\"".$tabletId."\" AND CopyRequested=\"true\"";
		$queryRes = $this->db->query($q);
			
		while ($episode = $queryRes->fetchArray())
		{
            if (!isset($episode['Location'])) continue; 
            $download = str_replace("/media/divers/Videos/Series/", "http://".$_SERVER['HTTP_HOST']."/downloads/", $episode['Location']);
			$episodes[$episode['Id']] = $download;
        }
        if (isset($episodes)){return $episodes;}
        else{return 0;}
    }

    public function getEpisodesOnTablet($tabletId)
    {
        $episodes;
        $i = 0;
        $q = "SELECT Id FROM unseenEpisodes WHERE Tablet=\"".$tabletId."\" AND IsOnTablet=\"true\"";
		$queryRes = $this->db->query($q);
			
		while ($episode = $queryRes->fetchArray())
		{
            if (!isset($episode['Id'])) continue; 
            $episodes[$i] = $episode['Id'];
            $i++;
        }
        if (isset($episodes)){return $episodes;}
        else{return 0;}
    }

    public function updateEpisodeStatus($id)
    {
        $episodes;
        $q = "UPDATE unseenEpisodes SET CopyRequested = \"false\", IsOnTablet = \"true\" WHERE Id=\"".$id."\"";
		$queryRes = $this->db->query($q);
		return $queryRes;
    }

    public function removeEpisodeFromTablet($id)
    {
        $episodes;
        $q = "UPDATE unseenEpisodes SET CopyRequested = \"false\", IsOnTablet = \"false\" WHERE Id=\"".$id."\"";
		$queryRes = $this->db->query($q);
		return $queryRes;
    }

    public function removeEpisode($id)
    {
        $episodes;
        $q = "DELETE FROM unseenEpisodes WHERE Id=\"".$id."\"";
		$queryRes = $this->db->query($q);
		return $queryRes;
    }
}