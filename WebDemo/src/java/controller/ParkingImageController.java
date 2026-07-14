package controller;

import java.io.IOException;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet(
        name = "ParkingImageServlet",
        urlPatterns = {"/parking-image/*"}
)
public class ParkingImageController extends HttpServlet {

    private Path imageRoot;

    @Override
    public void init() throws ServletException {
        imageRoot = findImageRoot();

        if (imageRoot == null) {
            throw new ServletException(
                    "Cannot find Code/SmartParkingYOLO directory"
            );
        }

        System.out.println(
                "[ParkingImageServlet] Image root: " + imageRoot
        );
    }

    private Path findImageRoot() {
        /*
         * Khi chạy bằng NetBeans, getRealPath("/") thường trỏ tới:
         * WebDemo/build/web/
         *
         * Servlet sẽ đi ngược lên và tìm:
         * Code/SmartParkingYOLO/
         */
        String webRoot = getServletContext().getRealPath("/");

        if (webRoot != null) {
            Path result = searchFrom(Paths.get(webRoot));

            if (result != null) {
                return result;
            }
        }

        /*
         * Dự phòng nếu getRealPath("/") không dùng được.
         */
        Path userDirectory = Paths.get(
                System.getProperty("user.dir")
        );

        return searchFrom(userDirectory);
    }

    private Path searchFrom(Path startDirectory) {
        Path current = startDirectory
                .toAbsolutePath()
                .normalize();

        while (current != null) {
            Path candidate = current.resolve(
                    Paths.get("Code", "SmartParkingYOLO")
            );

            if (Files.isDirectory(candidate)) {
                return candidate
                        .toAbsolutePath()
                        .normalize();
            }

            current = current.getParent();
        }

        return null;
    }

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response
    ) throws ServletException, IOException {

        String requestedPath = request.getPathInfo();

        if (requestedPath == null
                || requestedPath.trim().isEmpty()
                || "/".equals(requestedPath)) {

            response.sendError(
                    HttpServletResponse.SC_BAD_REQUEST,
                    "Image path is required"
            );
            return;
        }

        // Bỏ dấu "/" ở đầu path
        while (requestedPath.startsWith("/")) {
            requestedPath = requestedPath.substring(1);
        }

        Path imageFile = imageRoot
                .resolve(requestedPath)
                .normalize();

        /*
         * Ngăn các URL dạng:
         * /parking-image/../../some-file
         */
        if (!imageFile.startsWith(imageRoot)) {
            response.sendError(
                    HttpServletResponse.SC_FORBIDDEN,
                    "Invalid image path"
            );
            return;
        }

        if (!Files.exists(imageFile)
                || !Files.isRegularFile(imageFile)) {

            System.out.println(
                    "[ParkingImageServlet] Image not found: "
                    + imageFile
            );

            response.sendError(
                    HttpServletResponse.SC_NOT_FOUND,
                    "Image not found"
            );
            return;
        }

        String contentType = getServletContext()
                .getMimeType(imageFile.getFileName().toString());

        if (contentType == null) {
            contentType = Files.probeContentType(imageFile);
        }

        if (contentType == null
                || !contentType.startsWith("image/")) {

            response.sendError(
                    HttpServletResponse.SC_UNSUPPORTED_MEDIA_TYPE,
                    "Requested file is not an image"
            );
            return;
        }

        response.setContentType(contentType);
        response.setContentLengthLong(Files.size(imageFile));

        // Tránh trình duyệt giữ ảnh cũ
        response.setHeader(
                "Cache-Control",
                "no-cache, no-store, must-revalidate"
        );
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);

        try (OutputStream output
                = response.getOutputStream()) {

            Files.copy(imageFile, output);
            output.flush();
        }
    }
}