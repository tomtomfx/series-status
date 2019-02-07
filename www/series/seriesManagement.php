<?php

class seriesManagement {

	private $dbfile = "series.db";
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
		$q = "SELECT * FROM unseenEpisodes WHERE Show='$show'";
		$queryRes = $this->db->query($q);
		
		while ($episode = $queryRes->fetchArray())
		{
			if (!isset($episode['Id'])) continue; 
			
			$episodes[$i] = $episode;
			$i++;
		}
		return $episodes;
	}

	public function getEpisodes($removeArchived) {
		$episodes = "";
		$i = 0;
		
		$q = "SELECT * FROM unseenEpisodes ORDER BY Show, Id";
		$queryRes = $this->db->query($q);
		
		while ($episode = $queryRes->fetchArray())
		{
			if (!isset($episode['Id'])) continue; 
			if ($removeArchived == true and $episode['Archived'] == "TRUE") continue;
			
			$episodes[$i] = $episode;
			$i++;
		}
		return $episodes;
	}
	
	public function getShows($removeArchived) {
		$shows = "";
		$i = 0;
		$q = 'SELECT Show, Archived FROM unseenEpisodes';
		$queryRes = $this->db->query($q);
			
		while ($show = $queryRes->fetchArray())
		{
			if (!isset($show['Show'])) continue; 
			
			if ($removeArchived == true and $show['Archived'] == "TRUE") continue;
			
			$shows[$i] = $show['Show'];
			$i++;
		}
		$shows = array_unique($shows, SORT_STRING);
		return $shows;
	}
}

$seriesManager = new seriesManagement();
$seriesManager->dbinit();

//**********************************************************************************************************************// fonctions PHP
// Write all episodes 
function printEpisodes ($seriesManager)
{

	$episodes = $seriesManager->getEpisodes(true);
	$nbEpisodes = count($episodes);
	
	$glyph = "glyphicon-folder-open";	
	echo'
		<div class="panel panel-default" id="panelGlobal">
			<div class="panel-heading" id="panelHead">
				<h2 class="panel-title" id="panelTitle"><span class="glyphicon '.$glyph.'" id="panelGlyph"></span>Episodes to see<span class="badge badge-primary" id="nbEpBadge">'.$nbEpisodes.'</span></h2>
			</div>
			<table class="table table-hover">
			<thead><tr>
				<th class="col-xs-2">Show</th>
				<th class="col-xs-1">Episode</th>
				<th class="col-xs-4">Title</th>
				<th class="col-xs-2">Status</th>
				<th id="CenteredTitle" class="col-xs-2">Actions</th>
			</tr></thead>
			<tbody>								
	';
	foreach ($episodes as $episode)
	{
		$serieName = $episode['Show'];
		$serieNameUnderscore = preg_replace('/ /', '_', $serieName);
		$serieNameUnderscore = preg_replace('/\(/', '\(', $serieNameUnderscore);
		$serieNameUnderscore = preg_replace('/\)/', '\)', $serieNameUnderscore);
		$episodeID = $episode['Id'];
		$IdBetaseries = $episode['IdBetaseries'];
		preg_match("#.+ - (.+)#", $episodeID, $matches);
		$episodeNumber = $matches[1];
		$episodeTitle = '&nbsp;';
		if (isset($episode['Title'])) $episodeTitle = $episode['Title'];
		$epStatus = $episode['Status'];
		$label = "info";
		switch ($epStatus)
		{
			case "To be watched":
				$label = "success";
				break;
			case "No subtitles found":
				$label = "warning";
				break;
			case "Download launched":
				$label = "info";
				break;
			case "Download failed":
				$label = "danger";
				break;
		}
		$action = "";
		if ($label == "success")
		{
			$action = '<a id="epAction" href="../cgi-bin/update.cgi?ep='.$serieNameUnderscore.'-'.$episodeNumber.'-'.$IdBetaseries.'"><span class="glyphicon glyphicon-eye-open"></span></a>';
			// $action = $action.'<a id="epAction" href="./tablet.php?id='.urlencode($episode['Id']).'&action=copy"><span class="glyphicon glyphicon-plus"></span></a>';
		}			
		echo'
					<tr>
						<td id="show" class="col-xs-2"><img id="banniere2" class="img-responsive" src="../images/banners/'.$serieName.'" alt="'.$serieName.'"></td>
						<td id="epNumber" class="col-xs-1">'.$episodeNumber.'</td>
						<td id="epTitle" class="col-xs-4">'.$episodeTitle.'</td>
						<td id="epStatus" class="col-xs-2"><span class="label label-'.$label.'">'.$epStatus.'</span></td>
						<td id="epNext" class="col-xs-2" text-align="center">'.$action.'</td>
					</tr>
		';
	}
	echo'
				</tbody>
			</table>
		</div>
	';
}						

// Form combo
function formCombo ($label, $seriesManager)
{
	$shows = $seriesManager->getShows(true);
	echo'
								<div class="row">
									<div class="form-group">
										<label class="col-xs-offset-1 col-xs-3 control-label">'.$label.'</label>
										<div class="col-xs-6">
											<select name="showId" class="form-control">
	';
	foreach ($shows as $show) {
		echo'
											<option>'.$show.'</option>
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