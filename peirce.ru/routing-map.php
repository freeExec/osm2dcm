<?php
#============================================
#(c) Zkir 2010
#============================================
include("ZSitePage.php");

  $zPage=new TZSitePage;
  $mapid=$_GET['mapid'];
  if ($mapid=="")  $mapid="RU-SPO";
  
  $zPage->title="Валидатор дорожного графа";
  $zPage->header="Валидатор дорожного графа";
  $zPage->WriteHtml('<h2>Тест рутингового графа ('.$mapid.')</h2>');
  $zPage->WriteHtml('<p style="text-align:right"><a href="/addr.php?mapid='.$mapid.'">Назад к таблице</a> </p>' );
  $zPage->WriteHtml('<p>Показываются "изоляты", т.е. дороги или группы дорог, не связанные с основным дорожным графом. ' );
  $zPage->WriteHtml('<a href="http://peirce.gis-lab.info/blog.php?postid=14435">Подробнее...</a> </p>' );
  	  
  $zPage->WriteHtml('
                    <div id="cm-example" style="width: 100%; height: 450px"></div> 
                    <script type="text/javascript" src="http://tile.cloudmade.com/wml/latest/web-maps-lite.js"></script>
                    <script type="text/javascript" src="http://peirce.gis-lab.info/js/routing-map.js"> </script> 
                    <script type="text/javascript">
                      ProcessMap("ADDR_CHK/'.$mapid.'.mp_addr.xml","");
                    </script> 
                    <img id="ttt" src="" style="display:none;" alt="Dummy item for JOSM" />
  	  ');
  $zPage->WriteHtml('<p>По щелчку на маркере открывается JOSM, он должен быть запущен</p>');

 $zPage->Output("1");
?>

