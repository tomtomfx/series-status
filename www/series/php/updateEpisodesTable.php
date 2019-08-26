<?php

include '../seriesManagement.php';

$seriesManager = new seriesManagement();
$seriesManager->configInit("../../secure/configWeb");
$seriesManager->dbinit("../series.db");

$content = printEpisodesToWatch($seriesManager);

$seriesManager->dbclose();

echo json_encode($content);

?>