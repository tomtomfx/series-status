
/*************************** Episodes management ****************************/
function updateEpisodeTable()
{
    $.ajax({
        url: 'php/updateEpisodesTable.php',
        method: 'POST',
        dataType: 'json',
        success: function(response){
            $("#panelGlobal").html(response);
        },
    });
}

function createArchiveShowList()
{
    $.ajax({
        url: 'php/updateArchiveShow.php',
        method: 'POST',
        dataType: 'json',
        success: function(response){
            $("#archiveShowList").html(response);
            $("#archiveSerie").modal("show");
        }
    });
}

function getShowList()
{
    search = document.getElementById("serie_name").value;
    $.ajax({
        url: 'php/searchShow.php',
        data: {serieName:search},
        method: 'POST',
        dataType: 'json',
        success: function(response){
            $("#searchShowCombo").html(response);
            $("#searchShow").modal("show");        
        }
    });
    $("#addSerie").modal("hide");
}


/*************************** Episodes on tablet ****************************/
function showRequestCopy(episode){
    document.getElementById("episodeToCopy").value = episode;
    $("#copyTablet").modal("show");
}

function requestCopy()
{
    episode = document.getElementById("episodeToCopy").value;
    tablet = document.getElementById("copyToTablet").value;
    $.ajax({
        url: 'php/setCopyRequested.php',
        data: {episode:episode, tabletId:tablet},
        method: 'POST',
        error: function(jqXHR, textStatus, errorThrown){
            console.log(jqXHR);
            console.log(textStatus);
            console.log(errorThrown);
        },
        success: function(){
            updateTabletTables();
        }
    });
    $("#copyTablet").modal("hide");
}

function cancelCopy(id)
{
    $.ajax({
        url: 'php/cancelCopy.php',
        data: {id:id},
        method: 'POST',
        error: function(jqXHR, textStatus, errorThrown){
            console.log(jqXHR);
            console.log(textStatus);
            console.log(errorThrown);
        },
        success: function(){
            updateTabletTables();
        }
    });
    
}

function updateTabletTables()
{
    $.ajax({
        url: 'php/updateTabletTable.php',
        data: {tableName:"On tablet", panelId:"1"},
        method: 'POST',
        dataType: 'json',
        success: function(response){
            $("#panelGlobal1").html(response);
        },
    });
    $.ajax({
        url: 'php/updateTabletTable.php',
        data: {tableName:"Copy requested", panelId:"2"},
        method: 'POST',
        dataType: 'json',
        success: function(response){
            $("#panelGlobal2").html(response);
        },
    });
    $.ajax({
        url: 'php/updateTabletTable.php',
        data: {tableName:"Available", panelId:"3"},
        method: 'POST',
        dataType: 'json',
        success: function (response){
            $("#panelGlobal3").html(response);
        }
    });
}

/*************************** Tablets list ****************************/
function addTablet()
{
    tabletId = document.getElementById("tabletId").value;
    tabletIP = document.getElementById("tabletIP").value;
    $.ajax({
        url: 'php/addTablet.php',
        data: {tabletId:tabletId, tabletIP:tabletIP},
        method: 'POST',
        error: function(jqXHR, textStatus, errorThrown){
            console.log(jqXHR);
            console.log(textStatus);
            console.log(errorThrown);
        },
        success: function(){
            updateTabletsList();
        }
    });
    $("#addTablet").modal("hide");
}

function removeTablet()
{
    tabletId = document.getElementById("removeTabletId").value;
    $.ajax({
        url: 'php/removeTablet.php',
        data: {tabletId:tabletId},
        method: 'POST',
        success: function(msg){
            updateTabletsList();
        }
    });
    $("#removeTablet").modal("hide");
}

function updateTabletsList()
{
    // Update tablet in the table
    $.ajax({
        url: 'php/updateTabletsList.php',
        method: 'POST',
        dataType: 'json',
        success: function(response){
            $("#panelGlobalTablets").html(response);
        },
    });

    // Update list of tablets that can be removed
    $.ajax({
        url: 'php/updateTabletsToRemove.php',
        method: 'POST',
        dataType: 'json',
        success: function(response){
            $("#removeTabletIdCombo").html(response);
        },
    });

    // Update list of tablets episodes can be copied to
    $.ajax({
        url: 'php/updateTabletsToCopy.php',
        method: 'POST',
        dataType: 'json',
        success: function(response){
            $("#copyToTabletCombo").html(response);
        },
    });
    
}