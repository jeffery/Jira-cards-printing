<?php

define( 'CREDENTIALS_EXPIRE_OFFSET', 2592000 ); // 1 month

if(!empty($_POST['xml_url'])) {

    $docXML = $_POST['xml_url'];
    $username = $_POST['username'];
    $password = $_POST['password'];

    // add credentials to url
    $docXML = $docXML . "&os_username=$username&os_password=$password";
    $format = $_POST['format'];
    $remember = @$_POST['remember'];
    if ($remember === 'on') {
        setcookie('username', $username, time() + CREDENTIALS_EXPIRE_OFFSET);
        setcookie('password', $password, time() + CREDENTIALS_EXPIRE_OFFSET);
    } elseif (@$_COOKIE['username'] !== null) {
        // expire it
        setcookie('username', '', 0);
        setcookie('password', '', 0);
    }

    switch($format) {
        case '6PerPage':
            $docXSL = dirname(__FILE__) . '/xsl/6_per_page.xslt';
            break;
        case '1PerPage':
            $docXSL = dirname(__FILE__) . '/xsl/1_per_page.xslt';
            break;
        case '1PerPageWithSubtasks':
            $docXSL = dirname(__FILE__) . '/xsl/1_per_page_with_subtasks.xslt';
            break;
    }

    if ($format === '1PerPageWithSubtasks') {
        $domXML = populateSubtasks($docXML, $username, $password);
    } else {
        $domXML = new DomDocument();
        $domXML->load($docXML);
    }

    $domXSL = new DomDocument();
    $domXSL->load($docXSL);

    $xsl = new XsltProcessor();
    $xsl->importStylesheet($domXSL);
    echo $xsl->transformToXml($domXML);
}
else { ?>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <title>Jira cards generator</title>
        <link rel="stylesheet" type="text/css" media="all" href="css/style.css" />
    </head>
    <body>
        <img class="logo" src="http://www.liip.ch/themes/liip/images/logo-liip.gif" alt="Liip logo" />
        <h1>Jira Cards Generator</h1>
        <form method="post" action="<?php echo $_SERVER['PHP_SELF']; ?>">
            <div>
                <label for="xml_url">Paste the XML url of your Jira stories:</label>
                <input id="xml_url" type="text" value="" name="xml_url" />
            </div>
            <div>
                <label for="username">Jira username:</label>
                <input id="username" type="text" value="<?php echo isset($_COOKIE['username']) ? $_COOKIE['username'] : '';?>" name="username" />
            </div>
            <div>
                <label for="password">Jira password:</label>
                <input id="password" type="password" name="password" value="<?php echo isset($_COOKIE['password']) ? $_COOKIE['password'] : '';?>"/>
            </div>
            <div>
                <label for="remember">Remember credentials:</label>
                <input id="remember" type="checkbox" name="remember" <?php echo isset($_COOKIE['username']) ? 'checked' : '';?> />
            </div>

            <div>
                <label>format:</label>
                <div>
                    <input id="6PerPage" type="radio" name="format" value="6PerPage" checked />
                    <label class="inline" for="6PerPage">6 cards per page</label>
                    <br />
                    <input id="1PerPage" type="radio" name="format" value="1PerPage"/>
                    <label class="inline" for="1PerPage">1 card per page</label>
                    <br />
                    <input id="1PerPageWithSubtasks" type="radio" name="format" value="1PerPageWithSubtasks"/>
                    <label class="inline" for="1PerPageWithSubtasks">1 card per page with subtasks</label>
                </div>
            </div>

            <div>
                <label>&nbsp;</label>
                <input type="submit" value="Get cards" />
            </div>
        </form>
        <p class="credits">Brought to you by Sébastien Roch. Feedback welcome!</p>
    </body>
</html><?php
}

/**
 * Create an XML DOM object with the given source path.
 * For each tasks found in this DOM,
 * fetch its subtask and update the DOM accordingly.
 *
 * @param string $docXML
 * @param string $username
 * @param string $password
 *
 * @return \DomDocument object containing all the tasks and their subtasks
 */
function populateSubtasks($docXML, $username, $password)
{
    $urlParts = parse_url($docXML);

    // get the jira query
    $jiraQuery= urldecode(parse_url($docXML, PHP_URL_QUERY));
    parse_str($jiraQuery, $parts);
    $query = $parts['jqlQuery'];

    // find project name
    $res = preg_match('/project\s?=\s?(?:\\\")?(.+?)(\sAND\s|\sOR\s|\sORDER\s|\\\"|\s?$)/i', $query, $matches);
    $projectName = trim($matches[1]);
    // add quotes if project name contains spaces
    if (preg_match('/\s/', $projectName)) {
        $projectName = '"' . trim($projectName, '"') . '"';
    }

    // load XML and get all subtasks ids
    $domXML = new DomDocument();
    $domXML->load($docXML);
    $xpath = new DOMXPath($domXML);
    $query = '//rss/channel/item';
    $items = $xpath->query($query);

    // store all subtasks keys into an array
    $taskKeys = array();
    foreach ($items as $item) {
        $subtasks = $xpath->query('.//subtasks/subtask', $item);
        foreach($subtasks as $task) {
            $taskKeys[$task->attributes->getNamedItem('id')->nodeValue] = $task->nodeValue;
        }
    }

    if (count($taskKeys) > 0) {
        // get subtasks from Jira
        $query = "project=$projectName AND key IN (".implode(',', $taskKeys).")";
        //$query .= " AND type = 'Technical task'";

        $url = $urlParts['scheme'].'://'.$urlParts['host'].$urlParts['path'];
        $url .= '?jqlQuery='.urlencode($query);
        $url .= "&os_username=$username&os_password=$password"; // credentials
        $url .= '&tempMax=100&reset=true'; // put some limit in case of...

        $subtasksXML = file_get_contents($url);

        if($subtasksXML) {
            // this is useful for later
            $key2id = array_flip($taskKeys);

            // load the download subtasks
            $domSubtasksXML = new DomDocument();
            $domSubtasksXML->loadXML($subtasksXML);

            // get them all
            $xpathSubtasks = new DOMXPath($domSubtasksXML);
            $query = "//rss/channel/item";
            $subtasks = $xpathSubtasks->query($query);

            // Walk through each subtask and find the parent key. When found,
            // append the subtask details in the right node
            foreach ($subtasks as $task) {
                // get parent key
                $parentNode = $xpathSubtasks->query('.//parent', $task);
                $parent = $parentNode->item(0)->nodeValue;

                // get subtask key
                $keyNode = $xpathSubtasks->query('.//key', $task);
                $key = $keyNode->item(0)->nodeValue;

                // find the parent and append the subtask node to the subtask node of the parent
                foreach ($items as $item) {
                    $itemKeyNode = $xpath->query('.//key', $item);
                    $itemKey = $itemKeyNode->item(0)->nodeValue;

                    if ($itemKey == $parent) {
                        // find the subtask node of the parent
                        $subtasks = $xpath->query(".//subtasks/subtask[@id='".$key2id[$key]."']", $item);
                        $subtaskNode = $subtasks->item(0);

                        // append the subtask to the parent subtask node
                        $imported = $domXML->importNode($task, true);
                        $subtaskNode->appendChild($imported);
                        break;
                    }
                }
            }
        }
    }
    $xml = $domXML->saveXML();
    return $domXML;
}
