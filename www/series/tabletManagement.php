<?php

class tabletManagement {

	private $dbfile = "tablet.db";
	private $db = -1;
	
	public function dbinit() {
		if ($this->db == -1) 
			$this->db = new SQLite3($this->dbfile);
	}
	
	public function dbclose() {
		$this->db->close();
		$this->db = -1;	
	}
		
	public function getEpisodesFromShow($show) {
		$episodes = "";
		$i = 0;
		$q = "SELECT * FROM Episodes WHERE SerieName='$show'";
		$queryRes = $this->db->query($q);
		
		while ($episode = $queryRes->fetchArray())
		{
			if (!isset($episode['EpisodeNumber'])) continue; 
			
			$episodes[$i] = $episode;
			$i++;
		}
		return $episodes;
	}

	public function getEpisodesFromStatus($status) {
		$episodes = "";
		$i = 0;
		// Set where depending on the requested status
		$where = "";
		if ($status == "Available"){$where = "isOnTablet='false' AND copyRequested='false'";}
		else if ($status == "On tablet"){$where = "isOnTablet='true'";}
		else if ($status == "Copy requested"){$where = "copyRequested='true'";}
		else return 0;
		
		$q = "SELECT * FROM Episodes WHERE ".$where." ORDER BY SerieName";
		$queryRes = $this->db->query($q);
		
		while ($episode = $queryRes->fetchArray())
		{
			if (!isset($episode['EpisodeNumber'])) continue; 
			
			$episodes[$i] = $episode;
			$i++;
		}
		return $episodes;
	}
	
	public function getShows() {
		$shows = "";
		$i = 0;
		$q = 'SELECT SerieName FROM Episodes';
		$queryRes = $this->db->query($q);
			
		while ($show = $queryRes->fetchArray())
		{
			if (!isset($show['SerieName'])) continue; 
			
			$shows[$i] = $show['SerieName'];
			$i++;
		}
		$shows = array_unique($shows, SORT_STRING);
		return $shows;
	}
	
	public function copyRequested($episodeId, $tablet, $doCopy) {
		$q = "UPDATE Episodes SET copyRequested='".$doCopy."', tablet='".$tablet."' WHERE id='".$episodeId."'";
		// var_dump ($q);
		$this->db->query($q);
	}
	
	public function addTablet ($id, $ipAddr, $user, $password)
	{
		// Check if table Tablets exists. If not create it.
		$q = "SELECT COUNT(*) FROM sqlite_master WHERE name='Tablets' and type='table'";
		$queryRes = $this->db->query($q);
		$tableExists = $queryRes->fetchArray();
		if ($tableExists[0] == 0){
			$this->db->exec('CREATE TABLE Tablets (id TEXT PRIMARY KEY, ip TEXT, ftpUser TEXT, ftpPassword TEXT, status TEXT)');
		}
		// Insert new tablet into database
		// Check if id already exists
		$q = "SELECT COUNT(id) FROM Tablets WHERE id='$id'";
		$queryRes = $this->db->query($q);
		$tabletExists = $queryRes->fetchArray();
		if ($tabletExists[0] == 0){
			$q = 'INSERT INTO Tablets (id, ip, ftpUser, ftpPassword) VALUES ("'.$id.'", "'.$ipAddr.'", "'.$user.'", "'.$password.'")';
			$this->db->exec($q);
		}
	}
	public function getTablets()
	{
		$tablets = "";
		$i = 0;
		$q = 'SELECT * FROM Tablets';
		$queryRes = $this->db->query($q);
		if ($queryRes != false)
		{
			while ($tablet = $queryRes->fetchArray())
			{
				$tablets[$i] = $tablet;
				$i++;
			}
		}
		else {$tablets = 0;}
		return $tablets;
	}
	public function removeTablet ($id)
	{
		$q = 'DELETE FROM Tablets WHERE id=\''.$id.'\'';
		$queryRes = $this->db->query($q);
	}
}

$tabletManager = new tabletManagement();
$tabletManager->dbinit();

//**********************************************************************************************************************// fonctions PHP
// Write all episodes from a status 
function printEpisodes ($status, $tabletManager)
{

	$episodes = $tabletManager->getEpisodesFromStatus($status);
	$nbEpisodes = count($episodes);
	
	$glyph = "glyphicon-folder-open";
	if ($status == "On tablet"){$glyph = "glyphicon-phone";} 
	elseif ($status == "Copy requested"){$glyph = "glyphicon-save";} 
	
	if (is_array($episodes) AND $status == "Available")
	{
		echo'
			<div class="panel panel-default" id="panelGlobal">
				<div class="panel-heading" id="panelHead">
					<h2 class="panel-title" id="panelTitle"><span class="glyphicon '.$glyph.'" id="panelGlyph"></span>'.$status.'<span class="badge badge-primary" id="nbEpBadge">'.$nbEpisodes.'</span></h2>
				</div>
				<table class="table table-condensed">
				<thead><tr>
					<th class="col-xs-4">Show</th>
					<th class="col-xs-1">Episode</th>
					<th class="col-xs-6">Title</th>
					<th class="col-xs-1">Actions</th>
				</tr></thead>
				<tbody>								
		';
		foreach ($episodes as $episode)
		{
			$serieName = $episode['SerieName'];
			$episodeNumber = $episode['EpisodeNumber'];
			$episodeTitle = '&nbsp;';
			if (isset($episode['EpisodeTitle'])) $episodeTitle = $episode['EpisodeTitle'];

			$status = '&nbsp;';
			$action = '<a id="epAction" href="./tablet.php?id='.urlencode($episode['Id']).'&action=copy"><span class="glyphicon glyphicon-plus"></span></a>';			
			echo'
						<tr>
							<td class="col-xs-1">'.$serieName.'</td>
							<td class="col-xs-2">'.$episodeNumber.'</td>
							<td class="col-xs-6">'.$episodeTitle.'</td>
							<td class="col-xs-1" text-align="center">'.$action.'</td>
						</tr>
			';
		}
		echo'
					</tbody>
				</table>
			</div>
		';
	}

	elseif (is_array($episodes) AND ($status == "On tablet" OR $status == "Copy requested"))
	{
		echo'
			<div class="panel panel-default" id="panelGlobal">
				<div class="panel-heading" id="panelHead">
					<h2 class="panel-title" id="panelTitle"><span class="glyphicon '.$glyph.'" id="panelGlyph"></span>'.$status.'<span class="badge badge-primary" id="nbEpBadge">'.$nbEpisodes.'</span></h2>
				</div>
				<table class="table table-condensed">
				<thead><tr>
					<th class="col-xs-4">Show</th>
					<th class="col-xs-1">Episode</th>
					<th class="col-xs-4">Title</th>
					<th class="col-xs-2">Tablet</th>
					<th class="col-xs-1">Actions</th>
				</tr></thead>
				<tbody>								
		';
		foreach ($episodes as $episode)
		{
			$serieName = $episode['SerieName'];
			$episodeNumber = $episode['EpisodeNumber'];
			$tablet = $episode['tablet'];
			$episodeTitle = '&nbsp;';
			if (isset($episode['EpisodeTitle'])) $episodeTitle = $episode['EpisodeTitle'];

			if ($episode['copyRequested'] == "true")
			{
				$status = 'Copy requested';
				$action = '<a id="epAction" href="./tablet.php?id='.urlencode($episode['Id']).'&action=cancel" text-align="center"><span class="glyphicon glyphicon-remove"></span></a>';
			}
			else if ($episode['isOnTablet'] == "true")
			{
				$status = 'Copied';
				$action = '&nbsp;';
			}
			
			echo'
						<tr>
							<td class="col-xs-4">'.$serieName.'</td>
							<td class="col-xs-1">'.$episodeNumber.'</td>
							<td class="col-xs-4">'.$episodeTitle.'</td>
							<td class="col-xs-2">'.$tablet.'</td>
							<td class="col-xs-1" text-align="center">'.$action.'</td>
						</tr>
			';
		}
		echo'
					</tbody>
				</table>
			</div>
		';
	}
}						

// Write all episodes from a status 
function printTablets ($tabletManager)
{
	$tablets = $tabletManager->getTablets();
	if (is_array($tablets))
	{
		echo'
			<div class="panel panel-default" id="panelGlobal">
				<div class="panel-heading" id="panelHead">
					<h2 class="panel-title" id="panelTitle"><span class="glyphicon glyphicon-phone" id="panelGlyph"></span>Tablets</h2>
				</div>
				<table class="table table-condensed">
					<thead><tr>
						<th class="col-xs-6">Name</th>
						<th class="col-xs-6">Status</th>
					</tr></thead>
					<tbody>								
		';
		foreach ($tablets as $tablet)
		{
			$tabletName = $tablet['id'];
			$tabletStatus = "<span class=\"label label-warning\">Connection lost</span>";
			if ($tablet['status'] == 'OK'){$tabletStatus = "<span class=\"label label-success\">Available</span>";}
			echo'
						<tr>
							<td class="col-xs-6">'.$tabletName.'</td>
							<td class="col-xs-6">'.$tabletStatus.'</td>
						</tr>
			';
		}
		echo'
					</tbody>
				</table>
			</div>
		';
	}
}						

// Form text 
function formText ($label, $input, $status, $value, $editable)
{
	$formGroup = "form-group";
	$inputField = '<input name="'.$input.'" type="text" class="form-control" value="'.$value.'">';
	if ($editable == "false"){$inputField = '<input name="'.$input.'" type="text" class="form-control" value="'.$value.'" readonly>';}
	if ($status == "failed" AND $value == ""){$formGroup = "form-group has-error";}
	echo'
								<div class="row">
									<div class="'.$formGroup.'">
										<label class="col-xs-offset-1 col-xs-3 control-label">'.$label.' </label>
										<div class="col-xs-6">
											'.$inputField.'
										</div>
									</div>
								</div>
	';
}

// Form password 
function formPassword ($label, $input, $status, $value)
{
	$formGroup = "form-group";
	if ($status == "failed" AND $value == ""){$formGroup = "form-group has-error";}
	echo'
								<div class="row">
									<div class="'.$formGroup.'">
										<label class="col-xs-offset-1 col-xs-3 control-label">'.$label.' </label>
										<div class="col-xs-6">
											<input name="'.$input.'" type="password" class="form-control" value="'.$value.'">
										</div>
									</div>
								</div>
	';
}

// Form combo
function formCombo ($label, $tabletManager)
{
	$tablets = $tabletManager->getTablets();
	echo'
								<div class="row">
									<div class="form-group">
										<label class="col-xs-offset-1 col-xs-3 control-label">'.$label.'</label>
										<div class="col-xs-6">
											<select name="tabletId" class="form-control">
	';
	foreach ($tablets as $tablet) {
		echo'
											<option>'.$tablet['id'].'</option>
		';
	}
	echo'
											</select>
										</div>
									</div>
								</div>
	';
}

// Get a random image to diplay it as background
function getRandomBackground($dir)
{
	$images = array();
	$list = scandir($dir);
	foreach ($list as $file) {
		if (!isset($img)) {
			$img = '';
		}
		if (is_file($dir . '/' . $file)) {
			$tmp = explode('.', $file);
			$ext = end($tmp);
			if ($ext == 'jpg') 
			{
				array_push($images, $file);
				$img = $file;
			}
		}
	}
	if ($img != '') {
		$img = array_rand($images);
		$img = $images[$img];
	}
	$img = str_replace("'", "\'", $img);
	$img = str_replace(" ", "%20", $img);
	return $img;
}

//**********************************************************************************************************************// fonctions PHP


	
?>