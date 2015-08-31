/**
 * Copyright 2011 Pablo Mendes, Max Jakob
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.dbpedia.spotlight.util

import io.Source
import scala.collection.JavaConversions._
import org.apache.commons.logging.LogFactory
import java.util.{LinkedHashSet, LinkedList}
import java.io.{InputStream, File}
import org.semanticweb.yars.nx.parser.NxParser
import collection.JavaConversions
import org.dbpedia.spotlight.model._

/**
 * Created by IntelliJ IDEA.
 * User: Max
 * Date: 30.08.2010
 * Time: 13:08:23
 * To change this template use File | Settings | File Templates.
 */

object TypesLoader
{
    private val LOG = LogFactory.getLog(this.getClass)

    def getTypesMap(typeDictFile : File) : Map[String, List[OntologyType]] = {
        LOG.info("Loading types map...")
        if (!(typeDictFile.getName.toLowerCase endsWith ".tsv"))
            throw new IllegalArgumentException("types mapping only accepted in tsv format so far! can't parse "+typeDictFile)
        // CAUTION: this assumes that the most specific type is listed last
        var typesMap = Map[String,List[OntologyType]]()
        for (line <- Source.fromFile(typeDictFile, "UTF-8").getLines) {
            val elements = line.split("\t")
            val uri = new DBpediaResource(elements(0)).uri
            val t = Factory.OntologyType.fromURI(elements(1))
            val typesList : List[OntologyType] = typesMap.get(uri).getOrElse(List[OntologyType]()) ::: List(t)
            typesMap = typesMap.updated(uri, typesList)
        }
        LOG.info("Done.")
        typesMap
    }

    def getTypesMapFromTSV_java(input: InputStream) : java.util.Map[String,java.util.LinkedHashSet[OntologyType]] = {
        LOG.info("Loading types map...")
        var typesMap = Map[String,java.util.LinkedHashSet[OntologyType]]()
        var i = 0;
        for (line <- Source.fromInputStream(input, "UTF-8").getLines) {
            val elements = line.split("\t")
            val uri = new DBpediaResource(elements(0)).uri
            val typeUri = elements(1)
            if (!typeUri.equalsIgnoreCase("http://www.w3.org/2002/07/owl#Thing")) {
                val t = Factory.OntologyType.fromURI(typeUri)
                i = i + 1;
                val typesList : java.util.LinkedHashSet[OntologyType] = typesMap.getOrElse(uri,new LinkedHashSet[OntologyType]())
                typesList.add(t)
                t match {
                    case ft: FreebaseType => typesList.add(Factory.OntologyType.fromQName("Freebase:/"+ft.domain)) //Add supertype as well to mimic inference
                    case _ => //nothing
                }
                typesMap = typesMap.updated(uri, typesList)
            }
        }
        LOG.info("Done. Loaded %d types for %d resources.".format(i,typesMap.size))
        typesMap
    }


    def getTypesMap_java(instanceTypesStream : InputStream) : java.util.Map[String,java.util.LinkedHashSet[OntologyType]] = {
        LOG.info("Loading types map...")
        var typesMap = Map[String,java.util.LinkedHashSet[OntologyType]]()
        var i = 0;
        // CAUTION: this assumes that the most specific type is listed last
        val parser = new NxParser(instanceTypesStream)
        while (parser.hasNext) {
            val triple = parser.next
            if(!triple(2).toString.endsWith("owl#Thing")) {
                i = i + 1;
                val resource = new DBpediaResource(triple(0).toString)
                val t = Factory.OntologyType.fromURI(triple(2).toString)
                val typesList : java.util.LinkedHashSet[OntologyType] = typesMap.get(resource.uri).getOrElse(new LinkedHashSet[OntologyType]())
                typesList.add(t)
                typesMap = typesMap.updated(resource.uri, typesList)
            }
        }
        LOG.info("Done. Loaded %d types.".format(i))
        typesMap
    }

  def getTitlesMap_java(instanceTypesStream : InputStream) : java.util.Map[String,java.util.LinkedHashSet[String]] = {
    LOG.info("Loading titles map...")
    var titlesMap = Map[String,java.util.LinkedHashSet[String]]()
    var i = 0;
    // CAUTION: this assumes that the most specific type is listed last
    val parser = new NxParser(instanceTypesStream)
    while (parser.hasNext) {
      val triple = parser.next
      if(!triple(2).toString.endsWith("owl#Thing")) {
        i = i + 1;
        val resource = new DBpediaResource(triple(0).toString)
        val t = triple(2).toString
        val titleList : java.util.LinkedHashSet[String] = titlesMap.get(resource.uri).getOrElse(new LinkedHashSet[String]())
        titleList.add(t)
        titlesMap = titlesMap.updated(resource.uri, titleList)
      }
    }
    LOG.info("Done. Loaded %d titles.".format(i))
    titlesMap
  }

  def getImagesMap_java(instanceTypesStream : InputStream) : java.util.Map[String,java.util.LinkedHashSet[String]] = {
    println("fede2")
    LOG.info("Loading images map...")
    var titlesMap = Map[String,java.util.LinkedHashSet[String]]()
    var i = 0;
    // CAUTION: this assumes that the most specific type is listed last
    val parser = new NxParser(instanceTypesStream)
    while (parser.hasNext) {
      val triple = parser.next
      if(triple(0).toString.startsWith("http://dbpedia.org") && triple(1).toString.startsWith("http://xmlns.com/foaf/0.1/depiction")) {
        i = i + 1;
        val resource = new DBpediaResource(triple(0).toString)
        val t = triple(2).toString
        val titleList : java.util.LinkedHashSet[String] = titlesMap.get(resource.uri).getOrElse(new LinkedHashSet[String]())
        titleList.add(t)
        titlesMap = titlesMap.updated(resource.uri, titleList)
      }
    }
    LOG.info("Done. Loaded %d images.".format(i))
    titlesMap
  }

  def getImagesMap_italian_java(instanceTypesStream : InputStream) : java.util.Map[String,java.util.LinkedHashSet[String]] = {
    println("fede2")
    LOG.info("Loading italian images map...")
    var titlesMap = Map[String,java.util.LinkedHashSet[String]]()
    var i = 0;
    // CAUTION: this assumes that the most specific type is listed last
    val parser = new NxParser(instanceTypesStream)
    while (parser.hasNext) {
      val triple = parser.next
      if(triple(0).toString.startsWith("http://it.dbpedia.org") && triple(1).toString.startsWith("http://xmlns.com/foaf/0.1/depiction")) {
        i = i + 1;
        val resource = new DBpediaResource(triple(0).toString)
        val t = triple(2).toString
        val titleList : java.util.LinkedHashSet[String] = titlesMap.get(resource.uri).getOrElse(new LinkedHashSet[String]())
        titleList.add(t)
        titlesMap = titlesMap.updated(resource.uri, titleList)
      }
    }
    LOG.info("Done. Loaded %d images.".format(i))
    titlesMap
  }


  def getSomeAsMap_java(instanceTypesStream : InputStream) : java.util.Map[String,java.util.LinkedHashSet[String]] = {
    println("fede2")
    LOG.info("Loading someAs map...")
    var titlesMap = Map[String,java.util.LinkedHashSet[String]]()
    var i = 0;
    // CAUTION: this assumes that the most specific type is listed last
    val parser = new NxParser(instanceTypesStream)
    while (parser.hasNext) {
      val triple = parser.next
      if(triple(2).toString.startsWith("http://dbpedia.org")) {
        i = i + 1;
        val resource = new DBpediaResource(triple(0).toString)
        val t = triple(2).toString
        val titleList : java.util.LinkedHashSet[String] = titlesMap.get(resource.uri).getOrElse(new LinkedHashSet[String]())
        titleList.add(t)
        titlesMap = titlesMap.updated(resource.uri, titleList)
      }
    }
    LOG.info("Done. Loaded %d someAs.".format(i))
    titlesMap
  }
    
}