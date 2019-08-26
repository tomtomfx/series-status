<?php

include '../seriesManagement.php';

$tabletManager = new tabletManagement();
$tabletManager->dbinit("../series.db");

$content = printTablets($tabletManager);

$tabletManager->dbclose();

echo json_encode($content);

?>